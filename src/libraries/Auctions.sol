// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import './Buckets.sol';
import './Loans.sol';
import './Maths.sol';

library Auctions {

    struct Data {
        address head;
        address tail;
        uint256 liquidationBondEscrowed; // [WAD]
        mapping(address => Liquidation) liquidations;
        mapping(address => Kicker)      kickers;
    }

    struct Liquidation {
        address kicker;      // address that initiated liquidation
        uint256 bondSize;    // liquidation bond size
        uint256 bondFactor;  // bond factor used to start liquidation
        uint256 kickTime;    // timestamp when liquidation was started
        uint256 kickMomp;    // Momp when liquidation was started
        address prev;        // previous liquidated borrower in auctions queue
        address next;        // next liquidated borrower in auctions queue
    }

    struct Kicker {
        uint256 claimable; // kicker's claimable balance
        uint256 locked;    // kicker's balance of tokens locked in auction bonds
    }

    /**
     *  @notice The action cannot be executed on an active auction.
     */
    error AuctionActive();
    /**
     *  @notice Attempted auction to clear doesn't meet conditions.
     */
    error AuctionNotClearable();
    /**
     *  @notice Head auction should be cleared prior of executing this action.
     */
    error HeadNotCleared();
    /**
     *  @notice Actor is attempting to take or clear an inactive auction.
     */
    error NoAuction();
    /**
     *  @notice Take was called before 1 hour had passed from kick time.
     */
    error TakeNotPastCooldown();

    /*********************************/
    /***  Auctions Queue Functions ***/
    /*********************************/

    /**
     *  @notice Heals the debt of the given loan / borrower.
     *  @notice Updates kicker's claimable balance with bond size awarded and subtracts bond size awarded from liquidationBondEscrowed.
     *  @param  borrower_      Borrower whose debt is healed.
     *  @param  reserves_      Pool reserves.
     *  @param  bucketDepth_   Max number of buckets heal action should iterate through.
     *  @return healedDebt_    The amount of debt that was healed.
     *  @return totalForgived_ The amount of total forgived debt in the pool.
     *  @return remainingDebt_ The amount of total forgived debt in the pool.
     *  @return remainingCol_ The amount of total forgived debt in the pool.
     */
    function heal(
        Data storage self,
        Loans.Data storage loans_,
        mapping(uint256 => Buckets.Bucket) storage buckets_,
        Deposits.Data storage deposits_,
        address borrower_,
        uint256 reserves_,
        uint256 bucketDepth_
    ) internal returns (
        uint256 healedDebt_,
        uint256 totalForgived_,
        uint256 remainingDebt_,
        uint256 remainingCol_
    )
    {
        uint256 kickTime = self.liquidations[borrower_].kickTime;
        if (kickTime == 0) revert NoAuction();

        uint256 debtToHeal   = loans_.borrowers[borrower_].debt;
        remainingCol_ = loans_.borrowers[borrower_].collateral;
        if (
            (block.timestamp - kickTime > 72 hours)
            ||
            (debtToHeal > 0 && remainingCol_ == 0)
        ) {
            remainingDebt_ = debtToHeal;

            while (bucketDepth_ > 0) {
                // auction has debt to cover with remaining collateral
                uint256 hpbIndex;
                if (remainingDebt_ != 0 && remainingCol_ != 0) {
                    hpbIndex              = Deposits.findIndexOfSum(deposits_, 1);
                    uint256 hpbPrice      = PoolUtils.indexToPrice(hpbIndex);
                    uint256 clearableDebt = Maths.min(remainingDebt_, Deposits.valueAt(deposits_, hpbIndex));
                    clearableDebt         = Maths.min(clearableDebt, Maths.wmul(remainingCol_, hpbPrice));
                    uint256 clearableCol  = Maths.wdiv(clearableDebt, hpbPrice);

                    remainingDebt_ -= clearableDebt;
                    remainingCol_  -= clearableCol;

                    Deposits.remove(deposits_, hpbIndex, clearableDebt);
                    buckets_[hpbIndex].collateral += clearableCol;
                }

                // there's still debt to cover but no collateral left to auction, use reserve or forgive amount form next HPB
                if (remainingDebt_ != 0 && remainingCol_ == 0) {
                    if (reserves_ != 0) {
                        uint256 fromReserve =  Maths.min(remainingDebt_, reserves_);
                        reserves_      -= fromReserve;
                        remainingDebt_  -= fromReserve;
                        totalForgived_ += fromReserve;
                    } else {
                        hpbIndex           = Deposits.findIndexOfSum(deposits_, 1);
                        uint256 hpbDeposit = Deposits.valueAt(deposits_, hpbIndex);
                        uint256 forgiveAmt = Maths.min(remainingDebt_, hpbDeposit);

                        totalForgived_ += forgiveAmt;
                        remainingDebt_ -= forgiveAmt;

                        Deposits.remove(deposits_, hpbIndex, forgiveAmt);

                        if (buckets_[hpbIndex].collateral == 0 && forgiveAmt >= hpbDeposit) {
                            // existing LPB and LP tokens for the bucket shall become unclaimable.
                            buckets_[hpbIndex].lps = 0;
                            buckets_[hpbIndex].bankruptcyTime = block.timestamp;
                        }
                    }
                }

                // no more debt to cover, remove auction from queue
                if (remainingDebt_ == 0) {
                    _removeAuction(self, borrower_);
                    break;
                }

                --bucketDepth_;
            }

            // TODO: need to return healedCollateral_ so we can compute numofNFTIds to move
            // healedCollateral_ = loans_.borrowers[borrower_].collateral - remainingCollateral_;
            // stack overflow blocking this ^^
            healedDebt_ = debtToHeal - remainingDebt_;

            // save remaining debt and collateral after auction clear action
            loans_.borrowers[borrower_].debt       = remainingDebt_;
            loans_.borrowers[borrower_].collateral = remainingCol_;
        } else {
            revert AuctionNotClearable();
        }
    }

    /**
     *  @notice Removes a collateralized borrower from the auctions queue and repairs the queue order.
     *  @param  borrower_          Borrower whose loan is being placed in queue.
     *  @param  collateralization_ Borrower's collateralization.
     */
    function checkAndRemove(
        Data storage self,
        address borrower_,
        uint256 collateralization_
    ) internal {

        if (collateralization_ >= Maths.WAD && self.liquidations[borrower_].kickTime != 0) {
            _removeAuction(self, borrower_);
        }
    }

    /**
     *  @notice Called to start borrower liquidation and to update the auctions queue.
     *  @param  borrower_          Borrower address to liquidate.
     *  @param  borrowerDebt_      Borrower debt to be recovered.
     *  @param  thresholdPrice_    Current threshold price (used to calculate bond factor).
     *  @param  momp_              Current MOMP (used to calculate bond factor).
     *  @return kickAuctionAmount_ The amount that kicker should send to pool in order to kick auction.
     */
    function kick(
        Data storage self,
        address borrower_,
        uint256 borrowerDebt_,
        uint256 thresholdPrice_,
        uint256 momp_
    ) internal returns (uint256 kickAuctionAmount_) {

        uint256 bondFactor;
        // bondFactor = min(30%, max(1%, (neutralPrice - thresholdPrice) / neutralPrice))
        if (thresholdPrice_ >= momp_) {
            bondFactor = 0.01 * 1e18;
        } else {
            bondFactor = Maths.min(
                0.3 * 1e18,
                Maths.max(
                    0.01 * 1e18,
                    1e18 - Maths.wdiv(thresholdPrice_, momp_)
                )
            );
        }
        uint256 bondSize = Maths.wmul(bondFactor, borrowerDebt_);

        // update kicker balances
        Kicker storage kicker = self.kickers[msg.sender];
        kicker.locked += bondSize;
        if (kicker.claimable >= bondSize) {
            kicker.claimable -= bondSize;
        } else {
            kickAuctionAmount_ = bondSize - kicker.claimable;
            kicker.claimable = 0;
        }
        // update liquidationBondEscrowed accumulator
        self.liquidationBondEscrowed += bondSize;

        // record liquidation info
        Liquidation storage liquidation = self.liquidations[borrower_];
        liquidation.kicker     = msg.sender;
        liquidation.kickTime   = block.timestamp;
        liquidation.kickMomp   = momp_;
        liquidation.bondSize   = bondSize;
        liquidation.bondFactor = bondFactor;

        liquidation.next = address(0);
        if (self.head != address(0)) {
            // other auctions in queue, liquidation doesn't exist or overwriting.
            self.liquidations[self.tail].next = borrower_;
            liquidation.prev = self.tail;
        } else {
            // first auction in queue
            self.head = borrower_;
            liquidation.prev  = address(0);
        }

        // update liquidation with the new ordering
        self.tail = borrower_;
    }

    /**
     *  @notice Performs take collateral on an auction and updates bond size and kicker balance accordingly.
     *  @param  borrowerAddress_  Borrower address in auction.
     *  @param  borrower_         Borrower struct containing updated info of auctioned borrower.
     *  @param  maxCollateral_    The max collateral amount to be taken from auction.
     *  @return quoteTokenAmount_ The quote token amount that taker should pay for collateral taken.
     *  @return repayAmount_      The amount of debt (quote tokens) that is recovered / repayed by take.
     *  @return collateralTaken_  The amount of collateral taken.
     *  @return bondChange_       The change made on the bond size (beeing reward or penalty).
     *  @return isRewarded_       True if kicker is rewarded (auction price lower than neutral price), false if penalized (auction price greater than neutral price).
     */
    function take(
        Data storage self,
        address borrowerAddress_,
        Loans.Borrower memory borrower_,
        uint256 maxCollateral_
    ) internal returns (
        uint256 quoteTokenAmount_,
        uint256 repayAmount_,
        uint256 collateralTaken_,
        uint256 bondChange_,
        bool isRewarded_
    ) {
        Liquidation storage liquidation = self.liquidations[borrowerAddress_];
        if (liquidation.kickTime == 0) revert NoAuction();
        if (block.timestamp - liquidation.kickTime <= 1 hours) revert TakeNotPastCooldown();

        uint256 auctionPrice = PoolUtils.auctionPrice(
            liquidation.kickMomp,
            liquidation.kickTime
        );

        // calculate amount
        quoteTokenAmount_ = Maths.wmul(auctionPrice, Maths.min(borrower_.collateral, maxCollateral_));
        collateralTaken_  = Maths.wdiv(quoteTokenAmount_, auctionPrice);

        int256 bpf = PoolUtils.bpf(
            borrower_.debt,
            borrower_.collateral,
            borrower_.mompFactor,
            borrower_.inflatorSnapshot,
            liquidation.bondFactor,
            auctionPrice
        );

        repayAmount_ = Maths.wmul(quoteTokenAmount_, uint256(1e18 - bpf));
        if (repayAmount_ >= borrower_.debt) {
            repayAmount_      = borrower_.debt;
            quoteTokenAmount_ = Maths.wdiv(borrower_.debt, uint256(1e18 - bpf));
        }

        isRewarded_ = (bpf >= 0);
        if (isRewarded_) {
            // take is below neutralPrice, Kicker is rewarded
            bondChange_ = quoteTokenAmount_ - repayAmount_;
            liquidation.bondSize += bondChange_;
            self.kickers[liquidation.kicker].locked += bondChange_;
        } else {
            // take is above neutralPrice, Kicker is penalized
            bondChange_ = Maths.wmul(quoteTokenAmount_, uint256(-bpf));
            liquidation.bondSize -= Maths.min(liquidation.bondSize, bondChange_);
            if (bondChange_ >= self.kickers[liquidation.kicker].locked) {
                self.kickers[liquidation.kicker].locked = 0;
            }
            else self.kickers[liquidation.kicker].locked -= bondChange_;
        }
    }


    /***************************/
    /***  Internal Functions ***/
    /***************************/

    /**
     *  @notice Removes auction and repairs the queue order.
     *  @notice Updates kicker's claimable balance with bond size awarded and subtracts bond size awarded from liquidationBondEscrowed.
     *  @param  borrower_ Auctioned borrower address.
     */
    function _removeAuction(
        Data storage self,
        address borrower_
    ) internal {

        Liquidation memory liquidation = self.liquidations[borrower_];
        // update kicker balances
        Kicker storage kicker = self.kickers[liquidation.kicker];
        kicker.locked    -= liquidation.bondSize;
        kicker.claimable += liquidation.bondSize;

        if (self.head == borrower_ && self.tail == borrower_) {
            // liquidation is the head and tail
            self.head = address(0);
            self.tail = address(0);

        } else if(self.head == borrower_) {
            // liquidation is the head
            self.liquidations[liquidation.next].prev = address(0);
            self.head = liquidation.next;

        } else if(self.tail == borrower_) {
            // liquidation is the tail
            self.liquidations[liquidation.prev].next = address(0);
            self.tail = liquidation.prev;

        } else {
            // liquidation is in the middle
            self.liquidations[liquidation.prev].next = liquidation.next;
            self.liquidations[liquidation.next].prev = liquidation.prev;
        }
        // delete liquidation
         delete self.liquidations[borrower_];
    }


    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Check if there is an ongoing auction for current borrower and revert if such.
     *  @dev    Used to prevent an auctioned borrower to draw more debt or while in liquidation.
     *  @dev    Used to prevent kick on an auctioned borrower.
     *  @param  borrower_ Borrower address to check auction status for.
     */
    function revertIfActive(
        Data storage self,
        address borrower_
    ) internal view {
        if (self.liquidations[borrower_].kickTime != 0) revert AuctionActive();
    }

    /**
     *  @notice Check if head auction is clearable (auction is kicked and 72 hours passed since kick time or auction still has debt but no remaining collateral).
     *  @notice Revert if auction is clearable
     */
    function revertIfHeadClearable(
        Data storage self,
        Loans.Data storage loans_
    ) internal view {
        address head     = self.head;
        uint256 kickTime = self.liquidations[head].kickTime;
        if (
            kickTime != 0
            &&
            (
                block.timestamp - kickTime > 72 hours
                ||
                (loans_.borrowers[head].debt > 0 && loans_.borrowers[head].collateral == 0)
            )
        ) {
            revert HeadNotCleared();
        }
    }

}
