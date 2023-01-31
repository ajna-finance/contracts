// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    LoansState,
    PoolState
}                   from '../../interfaces/pool/commons/IPoolState.sol';
import {
    DrawDebtResult,
    RepayDebtResult
}                   from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _feeRate,
    _priceAt,
    _isCollateralized
}                           from '../helpers/PoolHelper.sol';
import { _revertOnMinDebt } from '../helpers/RevertsHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

import { Auctions } from './Auctions.sol';

/**
    @title  BorrowerActions library
    @notice External library containing logic for for pool actors:
            - Borrowers: pledge collateral and draw debt; repay debt and pull collateral
 */
library BorrowerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    struct DrawDebtLocalVars {
        bool    borrow;                // true if borrow action
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LPs (NFTs only)
        uint256 t0BorrowAmount;        // [WAD] t0 amount to borrow
        uint256 t0DebtChange;          // [WAD] additional t0 debt resulted from draw debt action
        bool    inAuction;             // true if loan is auctioned
        uint256 lupId;                 // id of new LUP
        bool    pledge;                // true if pledge action
        bool    stampT0Np;             // true if loan's t0 neutral price should be restamped (when drawing debt or pledge settles auction)
    }
    struct RepayDebtLocalVars {
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LPs (NFTs only)
        bool    inAuction;             // true if loan still in auction after repay, false otherwise
        uint256 newLup;                // [WAD] LUP after repay debt action
        bool    pull;                  // true if pull action
        bool    repay;                 // true if repay action
        bool    stampT0Np;             // true if loan's t0 neutral price should be restamped (when repay settles auction or pull collateral)
        uint256 t0DebtInAuctionChange; // [WAD] t0 change amount of debt after repayment
        uint256 t0RepaidDebt;          // [WAD] t0 debt repaid
    }

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error BorrowerNotSender();
    error BorrowerUnderCollateralized();
    error InsufficientCollateral();
    error LimitIndexReached();
    error NoDebt();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    write state:
     *              - Auctions._settleAuction:
     *                  - _removeAuction:
     *                      - decrement kicker locked accumulator, increment kicker claimable accumumlator
     *                      - decrement auctions count accumulator
     *                      - decrement auctions.totalBondEscrowed accumulator
     *                      - update auction queue state
     *              - Loans.update:
     *                  - _upsert:
     *                      - insert or update loan in loans array
     *                  - remove:
     *                      - remove loan from loans array
     *                  - update borrower in address => borrower mapping
     *  @dev    reverts on:
     *              - borrower not sender BorrowerNotSender()
     *              - borrower debt less than pool min debt AmountLTMinDebt()
     *              - limit price reached LimitIndexReached()
     *              - borrower cannot draw more debt BorrowerUnderCollateralized()
     *  @dev    emit events:
     *              - Auctions._settleAuction:
     *                  - AuctionNFTSettle or AuctionSettle
     */
    function drawDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external returns (
        DrawDebtResult memory result_
    ) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        DrawDebtLocalVars memory vars;

        vars.pledge       = collateralToPledge_ != 0;
        vars.borrow       = amountToBorrow_ != 0 || limitIndex_ != 0; // enable an intentional 0 borrow loan call to update borrower's loan state
        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        result_.t0PoolDebt     = poolState_.t0Debt;
        result_.poolDebt       = poolState_.debt;
        result_.poolCollateral = poolState_.collateral;

        if (vars.pledge) {
            // add new amount of collateral to pledge to borrower balance
            borrower.collateral  += collateralToPledge_;

            result_.newLup  = _lup(deposits_, result_.poolDebt);
            vars.inAuction = _inAuction(auctions_, borrowerAddress_);

            // if loan is auctioned and becomes collateralized by newly pledged collateral then settle auction
            if (
                vars.inAuction &&
                _isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)
            ) {
                // borrower becomes collateralized
                vars.inAuction = false;
                vars.stampT0Np = true;  // stamp borrower t0Np when exiting from auction

                result_.settledAuction = true;

                // remove debt from pool accumulator and settle auction
                result_.t0DebtInAuctionChange = borrower.t0Debt;

                // settle auction and update borrower's collateral with value after settlement
                (
                    result_.remainingCollateral,
                    vars.compensatedCollateral
                ) = Auctions._settleAuction(
                    auctions_,
                    buckets_,
                    deposits_,
                    borrowerAddress_,
                    borrower.collateral,
                    poolState_.poolType
                );

                borrower.collateral    = result_.remainingCollateral;
                result_.poolCollateral -= vars.compensatedCollateral;
            }

            // add new amount of collateral to pledge to pool balance
            result_.poolCollateral += collateralToPledge_;
        }

        if (vars.borrow) {
            // only intended recipient can borrow quote
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            vars.t0BorrowAmount = Maths.wdiv(amountToBorrow_, poolState_.inflator);

            // t0 debt change is t0 amount to borrow plus the origination fee
            vars.t0DebtChange = Maths.wmul(vars.t0BorrowAmount, _feeRate(poolState_.rate) + Maths.WAD);

            borrower.t0Debt += vars.t0DebtChange;

            vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

            // check that drawing debt doesn't leave borrower debt under pool min debt amount
            _revertOnMinDebt(
                loans_,
                result_.poolDebt,
                vars.borrowerDebt,
                poolState_.quoteDustLimit
            );

            // add debt change to pool's debt
            result_.t0PoolDebt += vars.t0DebtChange;
            result_.poolDebt   = Maths.wmul(result_.t0PoolDebt, poolState_.inflator);

            // determine new lup index and revert if borrow happens at a price higher than the specified limit (lower index than lup index)
            vars.lupId = _lupIndex(deposits_, result_.poolDebt);
            if (vars.lupId > limitIndex_) revert LimitIndexReached();

            // calculate new lup and check borrow action won't push borrower into a state of under-collateralization
            // this check also covers the scenario when loan is already auctioned
            result_.newLup = _priceAt(vars.lupId);

            if (!_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                revert BorrowerUnderCollateralized();
            }

            // stamp borrower t0Np when draw debt
            vars.stampT0Np = true;
        }

        // calculate LUP if it wasn't calculated previously
        if (!vars.pledge && !vars.borrow) {
            result_.newLup = _lup(deposits_, result_.poolDebt);
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            vars.borrowerDebt,
            poolState_.rate,
            result_.newLup,
            vars.inAuction,
            vars.stampT0Np
        );
    }

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    write state:
     *              - Auctions._settleAuction:
     *                  - _removeAuction:
     *                      - decrement kicker locked accumulator, increment kicker claimable accumumlator
     *                      - decrement auctions count accumulator
     *                      - decrement auctions.totalBondEscrowed accumulator
     *                      - update auction queue state
     *              - Loans.update:
     *                  - _upsert:
     *                      - insert or update loan in loans array
     *                  - remove:
     *                      - remove loan from loans array
     *                  - update borrower in address => borrower mapping
     *  @dev    reverts on:
     *              - no debt to repay NoDebt()
     *              - borrower debt less than pool min debt AmountLTMinDebt()
     *              - borrower not sender BorrowerNotSender()
     *              - not enough collateral to pull InsufficientCollateral()
     *  @dev    emit events:
     *              - Auctions._settleAuction:
     *                  - AuctionNFTSettle or AuctionSettle
     */
    function repayDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_
    ) external returns (
        RepayDebtResult memory result_
    ) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        RepayDebtLocalVars memory vars;

        vars.repay        = maxQuoteTokenAmountToRepay_ != 0;
        vars.pull         = collateralAmountToPull_     != 0;
        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        result_.t0PoolDebt     = poolState_.t0Debt;
        result_.poolDebt       = poolState_.debt;
        result_.poolCollateral = poolState_.collateral;

        if (vars.repay) {
            if (borrower.t0Debt == 0) revert NoDebt();

            if (maxQuoteTokenAmountToRepay_ == type(uint256).max) {
                vars.t0RepaidDebt = borrower.t0Debt;
            } else {
                vars.t0RepaidDebt = Maths.min(
                    borrower.t0Debt,
                    Maths.wdiv(maxQuoteTokenAmountToRepay_, poolState_.inflator)
                );
            }

            result_.t0PoolDebt -= vars.t0RepaidDebt;

            result_.poolDebt          = Maths.wmul(result_.t0PoolDebt,                  poolState_.inflator);
            result_.quoteTokenToRepay = Maths.wmul(vars.t0RepaidDebt,                   poolState_.inflator);
            vars.borrowerDebt         = Maths.wmul(borrower.t0Debt - vars.t0RepaidDebt, poolState_.inflator);

            // check that paying the loan doesn't leave borrower debt under min debt amount
            _revertOnMinDebt(
                loans_,
                result_.poolDebt,
                vars.borrowerDebt,
                poolState_.quoteDustLimit
            );

            result_.newLup = _lup(deposits_, result_.poolDebt);
            vars.inAuction = _inAuction(auctions_, borrowerAddress_);

            // if loan is auctioned and becomes collateralized by repaying debt then settle auction
            if (vars.inAuction) {
                if (_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                    // borrower becomes re-collateralized
                    vars.inAuction = false;
                    vars.stampT0Np = true;  // stamp borrower t0Np when exiting from auction

                    result_.settledAuction = true;

                    // remove entire borrower debt from pool auctions debt accumulator
                    result_.t0DebtInAuctionChange = borrower.t0Debt;

                    // settle auction and update borrower's collateral with value after settlement
                    (
                        result_.remainingCollateral,
                        vars.compensatedCollateral
                    ) = Auctions._settleAuction(
                        auctions_,
                        buckets_,
                        deposits_,
                        borrowerAddress_,
                        borrower.collateral,
                        poolState_.poolType
                    );

                    borrower.collateral    = result_.remainingCollateral;
                    result_.poolCollateral -= vars.compensatedCollateral;
                } else {
                    // partial repay, remove only the paid debt from pool auctions debt accumulator
                    result_.t0DebtInAuctionChange = vars.t0RepaidDebt;
                }
            }

            borrower.t0Debt -= vars.t0RepaidDebt;
        }

        if (vars.pull) {
            // only intended recipient can pull collateral
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            // calculate LUP only if it wasn't calculated in repay action
            if (!vars.repay) result_.newLup = _lup(deposits_, result_.poolDebt);

            uint256 encumberedCollateral = borrower.t0Debt != 0 ? Maths.wdiv(vars.borrowerDebt, result_.newLup) : 0;

            if (borrower.collateral - encumberedCollateral < collateralAmountToPull_) revert InsufficientCollateral();

            // stamp borrower t0Np when pull collateral action
            vars.stampT0Np = true;

            borrower.collateral    -= collateralAmountToPull_;
            result_.poolCollateral -= collateralAmountToPull_;
        }

        // calculate LUP if it wasn't calculated previously
        if (!vars.repay && !vars.pull) {
            result_.newLup = _lup(deposits_, result_.poolDebt);
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            vars.borrowerDebt,
            poolState_.rate,
            result_.newLup,
            vars.inAuction,
            vars.stampT0Np
        );
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Returns true if borrower is in auction.
     *  @dev    Used to accuratley increment and decrement t0DebtInAuction.
     *  @param  borrower_ Borrower address to check auction status for.
     *  @return  active_ Boolean, based on if borrower is in auction.
     */
    function _inAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal view returns (bool) {
        return auctions_.liquidations[borrower_].kickTime != 0;
    }

    function _lupIndex(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return Deposits.findIndexOfSum(deposits_, debt_);
    }

    function _lup(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return _priceAt(_lupIndex(deposits_, debt_));
    }

}
