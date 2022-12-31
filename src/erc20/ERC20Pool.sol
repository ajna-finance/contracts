// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './interfaces/IERC20Pool.sol';
import './interfaces/IERC20Taker.sol';
import '../base/FlashloanablePool.sol';

contract ERC20Pool is IERC20Pool, FlashloanablePool {
    using SafeERC20 for IERC20;

    /*****************/
    /*** Constants ***/
    /*****************/

    // immutable args offset
    uint256 internal constant COLLATERAL_SCALE = 93;

    /****************************/
    /*** Initialize Functions ***/
    /****************************/

    function initialize(
        uint256 rate_
    ) external override {
        if (poolInitializations != 0) revert AlreadyInitialized();

        inflatorState.inflator       = uint208(10**18);
        inflatorState.inflatorUpdate = uint48(block.timestamp);

        interestState.interestRate       = uint208(rate_);
        interestState.interestRateUpdate = uint48(block.timestamp);

        Loans.init(loans);

        // increment initializations count to ensure these values can't be updated
        poolInitializations += 1;
    }

    /******************/
    /*** Immutables ***/
    /******************/

    function collateralScale() external pure override returns (uint256) {
        return _getArgUint256(COLLATERAL_SCALE);
    }

    /***********************************/
    /*** Borrower External Functions ***/
    /***********************************/

    function drawDebt(
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external {
        (uint256 newLup, , uint256 t0DebtInAuctionChange, uint256 t0DebtChange) = _drawDebt(
            borrowerAddress_,
            amountToBorrow_,
            limitIndex_,
            collateralToPledge_
        );

        emit DrawDebt(borrowerAddress_, amountToBorrow_, collateralToPledge_, newLup);

        if (collateralToPledge_ != 0) {
            // update pool balances state
            if (t0DebtInAuctionChange != 0) {
                poolBalances.t0DebtInAuction -= t0DebtInAuctionChange;
            }
            poolBalances.pledgedCollateral += collateralToPledge_;

            // move collateral from sender to pool
            _transferCollateralFrom(msg.sender, collateralToPledge_);
        }

        if (amountToBorrow_ != 0) {
            // update pool balances state
            poolBalances.t0Debt += t0DebtChange;

            // move borrowed amount from pool to sender
            _transferQuoteToken(msg.sender, amountToBorrow_);
        }

    }

    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_
    ) external {
        (uint256 quoteTokenToRepay, uint256 newLup, ) = _repayDebt(borrowerAddress_, maxQuoteTokenAmountToRepay_, collateralAmountToPull_);

        emit RepayDebt(borrowerAddress_, quoteTokenToRepay, collateralAmountToPull_, newLup);

        if (quoteTokenToRepay != 0) {
            // move amount to repay from sender to pool
            _transferQuoteTokenFrom(msg.sender, quoteTokenToRepay);
        }
        if (collateralAmountToPull_ != 0) {
            // move collateral from pool to sender
            _transferCollateral(msg.sender, collateralAmountToPull_);
        }
    }

    /************************************/
    /*** Flashloan External Functions ***/
    /************************************/

    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes calldata data_
    ) external override(IERC3156FlashLender, FlashloanablePool) nonReentrant returns (bool) {
        if (token_ == _getArgAddress(QUOTE_ADDRESS)) return _flashLoanQuoteToken(receiver_, token_, amount_, data_);

        if (token_ == _getArgAddress(COLLATERAL_ADDRESS)) {
            _transferCollateral(address(receiver_), amount_);            
            
            if (receiver_.onFlashLoan(msg.sender, token_, amount_, 0, data_) != 
                keccak256("ERC3156FlashBorrower.onFlashLoan")) revert FlashloanCallbackFailed();

            _transferCollateralFrom(address(receiver_), amount_);
            return true;
        }

        revert FlashloanUnavailableForToken();
    }

    function flashFee(
        address token_,
        uint256
    ) external pure override(IERC3156FlashLender, FlashloanablePool) returns (uint256) {
        if (token_ == _getArgAddress(QUOTE_ADDRESS) || token_ == _getArgAddress(COLLATERAL_ADDRESS)) return 0;
        revert FlashloanUnavailableForToken();
    }

    function maxFlashLoan(
        address token_
    ) external view override(IERC3156FlashLender, FlashloanablePool) returns (uint256 maxLoan_) {
        if (token_ == _getArgAddress(QUOTE_ADDRESS) || token_ == _getArgAddress(COLLATERAL_ADDRESS)) {
            maxLoan_ = IERC20Token(token_).balanceOf(address(this));
        }
    }

    /*********************************/
    /*** Lender External Functions ***/
    /*********************************/

    function addCollateral(
        uint256 collateralAmountToAdd_,
        uint256 index_
    ) external override returns (uint256 bucketLPs_) {
        PoolState memory poolState = _accruePoolInterest();

        bucketLPs_ = LenderActions.addCollateral(
            buckets,
            deposits,
            collateralAmountToAdd_,
            index_
        );

        emit AddCollateral(msg.sender, index_, collateralAmountToAdd_, bucketLPs_);

        // update pool interest rate state
        _updateInterestState(poolState, _lup(poolState.debt));

        // move required collateral from sender to pool
        _transferCollateralFrom(msg.sender, collateralAmountToAdd_);
    }

    function removeCollateral(
        uint256 maxAmount_,
        uint256 index_
    ) external override returns (uint256 collateralAmount_, uint256 lpAmount_) {
        Auctions.revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        (collateralAmount_, lpAmount_) = LenderActions.removeMaxCollateral(
            buckets,
            deposits,
            maxAmount_,
            index_
        );

        // update pool interest rate state
        _updateInterestState(poolState, _lup(poolState.debt));

        emit RemoveCollateral(msg.sender, index_, collateralAmount_, lpAmount_);
        // move collateral from pool to lender
        _transferCollateral(msg.sender, collateralAmount_);
    }

    /*******************************/
    /*** Pool External Functions ***/
    /*******************************/

    function settle(
        address borrowerAddress_,
        uint256 maxDepth_
    ) external override {
        PoolState memory poolState = _accruePoolInterest();

        uint256 assets = Maths.wmul(poolBalances.t0Debt, poolState.inflator) + _getPoolQuoteTokenBalance();
        uint256 liabilities = Deposits.treeSum(deposits) + auctions.totalBondEscrowed + reserveAuction.unclaimed;

        Borrower storage borrower = loans.borrowers[borrowerAddress_];

        SettleParams memory params = SettleParams(
            {
                borrower:    borrowerAddress_,
                collateral:  borrower.collateral,
                t0Debt:      borrower.t0Debt,
                reserves:    (assets > liabilities) ? (assets-liabilities) : 0,
                inflator:    poolState.inflator,
                bucketDepth: maxDepth_
            }
        );
        (uint256 remainingCollateral, uint256 t0RemainingDebt) = Auctions.settlePoolDebt(
            auctions,
            buckets,
            deposits,
            params
        );

        // slither-disable-next-line incorrect-equality
        if (t0RemainingDebt == 0) {
            remainingCollateral = _settleAuction(params.borrower, remainingCollateral);
        }

        // update borrower state
        borrower.t0Debt     = t0RemainingDebt;
        borrower.collateral = remainingCollateral;

        // update pool balances state
        uint256 t0SettledDebt        = params.t0Debt - t0RemainingDebt;
        poolBalances.t0Debt          -= t0SettledDebt;
        poolBalances.t0DebtInAuction -= t0SettledDebt;

        uint256 settledCollateral      = params.collateral - remainingCollateral;
        poolBalances.pledgedCollateral -= settledCollateral;

        // update pool interest rate state
        poolState.collateral -= settledCollateral;
        _updateInterestState(poolState, _lup(poolState.debt));
    }

    function take(
        address        borrowerAddress_,
        uint256        collateral_,
        address        callee_,
        bytes calldata data_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();
        Borrower  memory borrower  = Loans.getBorrowerInfo(loans, borrowerAddress_);
        // revert if borrower's collateral is 0 or if maxCollateral to be taken is 0
        if (borrower.collateral == 0 || collateral_ == 0) revert InsufficientCollateral();

        TakeParams memory params = TakeParams(
            {
                borrower:       borrowerAddress_,
                collateral:     borrower.collateral,
                t0Debt:         borrower.t0Debt,
                takeCollateral: collateral_,
                inflator:       poolState.inflator
            }
        );
        uint256 collateralAmount;
        uint256 quoteTokenAmount;
        uint256 t0RepayAmount;
        uint256 t0DebtPenalty;
        (
            collateralAmount,
            quoteTokenAmount,
            t0RepayAmount,
            borrower.t0Debt,
            t0DebtPenalty,
        ) = Auctions.take(
            auctions,
            params
        );

        _takeFromLoan(poolState, borrower, params.borrower, collateralAmount, t0RepayAmount, t0DebtPenalty);

        _transferCollateral(callee_, collateralAmount);

        if (data_.length != 0) {
            IERC20Taker(callee_).atomicSwapCallback(
                collateralAmount / _getArgUint256(COLLATERAL_SCALE), 
                quoteTokenAmount / _getArgUint256(QUOTE_SCALE), 
                data_
            );
        }

        _transferQuoteTokenFrom(callee_, quoteTokenAmount);
    }

    /*******************************/
    /*** Pool Override Functions ***/
    /*******************************/

   /**
     *  @notice Settle an ERC20 pool auction, remove from auction queue and emit event.
     *  @param borrowerAddress_    Address of the borrower that exits auction.
     *  @param borrowerCollateral_ Borrower collateral amount before auction exit.
     *  @return floorCollateral_   Remaining borrower collateral after auction exit.
     */
    function _settleAuction(
        address borrowerAddress_,
        uint256 borrowerCollateral_
    ) internal override returns (uint256) {
        Auctions._removeAuction(auctions, borrowerAddress_);
        emit AuctionSettle(borrowerAddress_, borrowerCollateral_);
        return borrowerCollateral_;
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    function _transferCollateralFrom(address from_, uint256 amount_) internal {
        IERC20(_getArgAddress(COLLATERAL_ADDRESS)).safeTransferFrom(from_, address(this), amount_ / _getArgUint256(COLLATERAL_SCALE));
    }

    function _transferCollateral(address to_, uint256 amount_) internal {
        IERC20(_getArgAddress(COLLATERAL_ADDRESS)).safeTransfer(to_, amount_ / _getArgUint256(COLLATERAL_SCALE));
    }
}
