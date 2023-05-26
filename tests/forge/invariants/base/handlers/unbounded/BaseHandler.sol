// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import '@std/Test.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

import { Pool }             from 'src/base/Pool.sol';
import { PoolInfoUtils }    from 'src/PoolInfoUtils.sol';
import { PoolCommons }      from 'src/libraries/external/PoolCommons.sol';
import {
    MAX_FENWICK_INDEX,
    MAX_PRICE,
    MIN_PRICE,
    _indexOf
}                           from 'src/libraries/helpers/PoolHelper.sol';
import { Maths }            from 'src/libraries/internal/Maths.sol';

import { TokenWithNDecimals, BurnableToken } from '../../../../utils/Tokens.sol';

import '../../../interfaces/ITestBase.sol';

uint256 constant BORROWER_MIN_BUCKET_INDEX = 2600;
uint256 constant BORROWER_MAX_BUCKET_INDEX = 2620;

abstract contract BaseHandler is Test {

    using EnumerableSet for EnumerableSet.UintSet;

    // Tokens
    TokenWithNDecimals internal _quote;
    BurnableToken      internal _ajna;

    // Pool
    Pool          internal _pool;
    PoolInfoUtils internal _poolInfo;

    // Lender bucket index
    uint256 public LENDER_MIN_BUCKET_INDEX;
    uint256 public LENDER_MAX_BUCKET_INDEX;

    uint256 internal MIN_QUOTE_AMOUNT;
    uint256 internal MAX_QUOTE_AMOUNT;
    uint256 internal MIN_DEBT_AMOUNT;
    uint256 internal MAX_DEBT_AMOUNT;

    uint256 internal MIN_COLLATERAL_AMOUNT;
    uint256 internal MAX_COLLATERAL_AMOUNT;

    // Test invariant contract
    ITestBase internal testContract;

    // Modifiers
    address internal _actor;
    uint256 internal _lenderBucketIndex;
    uint256 internal _limitIndex;

    // deposits invariant test state
    uint256[7389]                                   internal fenwickDeposits;
    mapping(address => mapping(uint256 => uint256)) public lenderDepositTime; // mapping of lender address to bucket index to deposit time

    address[] public actors;
    mapping(bytes => uint256)   public numberOfCalls;  // Logging
    mapping(address => uint256[]) public touchedBuckets; // Bucket tracking

    // exchange rate invariant test state
    mapping(uint256 => bool)    public exchangeRateShouldNotChange; // bucket exchange rate invariant check
    mapping(uint256 => uint256) public previousExchangeRate;        // mapping from bucket index to exchange rate before action
    mapping(uint256 => uint256) public previousBankruptcy;          // mapping from bucket index to last bankruptcy before action

    // reserves invariant test state
    uint256 public previousReserves;    // reserves before action
    uint256 public increaseInReserves;  // amount of reserve increase
    uint256 public decreaseInReserves;  // amount of reserve decrease

    // Auction bond invariant test state
    uint256 public previousTotalBonds; // total bond before action
    uint256 public increaseInBonds;    // amount of bond increase
    uint256 public decreaseInBonds;    // amount of bond decrease

    // All Buckets used in invariant testing that also includes Buckets where collateral is added when a borrower is in auction and has partial NFT
    EnumerableSet.UintSet internal buckets;

    // auctions invariant test state
    bool                     public firstTake;        // if take is called on auction first time
    mapping(address => bool) public alreadyTaken;     // mapping borrower address to true if auction taken atleast once

    string  internal path = "logfile.txt";
    uint256 internal logFileVerbosity;

    constructor(
        address pool_,
        address ajna_,
        address quote_,
        address poolInfo_,
        address testContract_
    ) {
        // Tokens
        _ajna       = BurnableToken(ajna_);
        _quote      = TokenWithNDecimals(quote_);

        // Pool
        _pool     = Pool(pool_);
        _poolInfo = PoolInfoUtils(poolInfo_);

        // Test invariant contract
        testContract = ITestBase(testContract_);
        
        // Verbosity of Log file
        logFileVerbosity = uint256(vm.envOr("LOGS_VERBOSITY", uint256(0)));
    }

    /*****************/
    /*** Modifiers ***/
    /*****************/

    /**
     * @dev Use and update test invariant contract timestamp to make timestamp consistent throughout invariant test run.
     */
    modifier useTimestamps() {
        vm.warp(testContract.currentTimestamp());

        _;

        testContract.setCurrentTimestamp(block.timestamp);
    }

    /**
     * @dev Skips some time before each action
     */
    modifier skipTime(uint256 time_) {
        time_ = constrictToRange(time_, 0, vm.envOr("SKIP_TIME", uint256(24 hours)));
        vm.warp(block.timestamp + time_);

        uint256 maxPoolDebt = uint256(vm.envOr("MAX_POOL_DEBT", uint256(1e55)));
        (uint256 poolDebt, , ,) = _pool.debtInfo();

        while (maxPoolDebt < poolDebt) {

            (address borrower, , ) = _pool.loansInfo();

            // if prank already started in test then use change prank to change actor
            try vm.startPrank(borrower) {
            } catch {
                changePrank(borrower);
            }

            (uint256 debt,,) = _poolInfo.borrowerInfo(address(_pool), borrower);

            uint256 repayAmount = Maths.min(debt, poolDebt - maxPoolDebt);

            _repayBorrowerDebt(borrower, repayAmount);

            (poolDebt, , ,) = _pool.debtInfo();
        }

        // start prank for actor
        try vm.startPrank(_actor) {
        } catch {
            changePrank(_actor);
        }
        _;
    }

    modifier writeLogs() {
        _;
        if (logFileVerbosity > 0) {
            if (numberOfCalls["Write logs"]++ == 0) vm.writeFile(path, "");
            string memory data = string(abi.encodePacked("================= Handler Call : ", Strings.toString(numberOfCalls["Write logs"]), " =================="));
            printInNextLine(data);
            writePoolStateLogs();
            if (logFileVerbosity > 1) writeAuctionLogs();
            if (logFileVerbosity > 2) writeBucketsLogs();
            if (logFileVerbosity > 3) writeLenderLogs();
            if (logFileVerbosity > 4) writeBorrowerLogs();
        }
    }

    function writePoolStateLogs() internal {
        printInNextLine("== Pool State ==");

        uint256 pledgedCollateral = _pool.pledgedCollateral();
        printLog("Pledged Collateral       = ", pledgedCollateral);

        uint256 totalT0debt = _pool.totalT0Debt();
        printLog("Total t0 debt            = ", totalT0debt);

        (, , , uint256 pendingInflator, ) = _poolInfo.poolLoansInfo(address(_pool));
        printLog("Total debt               = ", Maths.wmul(totalT0debt, pendingInflator));

        uint256 totalAuctions = _pool.totalAuctionsInPool();
        printLog("Total Auctions           = ", totalAuctions);

        uint256 totalT0debtInAuction = _pool.totalT0DebtInAuction();
        printLog("Total t0 debt in auction = ", totalT0debtInAuction);

        printLog("Total debt in auction    = ", Maths.wmul(totalT0debtInAuction, pendingInflator));

        uint256 depositSize = _pool.depositSize();
        printLog("Total deposits           = ", depositSize);

        (uint256 totalBond, , , ) = _pool.reservesInfo();
        printLog("Total bond escrowed      = ", totalBond);

        (uint256 interestRate, ) = _pool.interestRateInfo();
        printLog("Interest Rate            = ", interestRate);

        printInNextLine("=======================");
    }

    function writeLenderLogs() internal {
        printInNextLine("== Lenders Details ==");
        string memory data;
        for (uint256 i = 0; i < actors.length; i++) {
            printLine("");
            printLog("Actor ", i + 1);
            for (uint256 j = 0; j < buckets.length(); j++) {
                uint256 bucketIndex = buckets.at(j);
                (uint256 lenderLps, ) = _pool.lenderInfo(bucketIndex, actors[i]);
                if (lenderLps != 0) {
                    data = string(abi.encodePacked("Lps at ", Strings.toString(bucketIndex), " = ", Strings.toString(lenderLps)));
                    printLine(data);
                }
            }
        }
        printInNextLine("=======================");
    }

    function writeBorrowerLogs() internal {
        printInNextLine("== Borrowers Details ==");
        for (uint256 i = 0; i < actors.length; i++) {
            printLine("");
            printLog("Actor ", i + 1);
            (uint256 debt, uint256 pledgedCollateral, ) = _poolInfo.borrowerInfo(address(_pool), actors[i]);
            if (debt != 0 || pledgedCollateral != 0) {
                printLog("Debt               = ", debt);
                printLog("Pledged collateral = ", pledgedCollateral);
            }
        }
        printInNextLine("=======================");
    }

    function writeBucketsLogs() internal {
        printInNextLine("== Buckets Detail ==");
        for (uint256 i = 0; i < buckets.length(); i++) {
            printLine("");
            uint256 bucketIndex = buckets.at(i);
            printLog("Bucket:", bucketIndex);
            (
                ,
                uint256 quoteTokens,
                uint256 collateral,
                uint256 bucketLP,
                uint256 scale,
                uint256 exchangeRate
            ) = _poolInfo.bucketInfo(address(_pool), bucketIndex);

            printLog("Quote tokens  = ", quoteTokens);
            printLog("Collateral    = ", collateral);
            printLog("Bucket Lps    = ", bucketLP);
            printLog("Scale         = ", scale);
            printLog("Exchange Rate = ", exchangeRate);
        }
        printInNextLine("=======================");
    }

    function writeAuctionLogs() internal {
        printInNextLine("== Auctions Details ==");
        string memory data;
        address nextBorrower;
        uint256 kickTime;
        uint256 kickMomp;
        uint256 bondFactor;
        uint256 bondSize;
        uint256 neutralPrice;
        (,,,,,, nextBorrower,,,) = _pool.auctionInfo(address(0));
        while (nextBorrower != address(0)) {
            data = string(abi.encodePacked("Borrower ", Strings.toHexString(uint160(nextBorrower), 20), " Auction Details :"));
            printInNextLine(data);
            (, bondFactor, bondSize, kickTime, kickMomp, neutralPrice,, nextBorrower,,) = _pool.auctionInfo(nextBorrower);

            printLog("Bond Factor   = ", bondFactor);
            printLog("Bond Size     = ", bondSize);
            printLog("Kick Time     = ", kickTime);
            printLog("Kick Momp     = ", kickMomp);
            printLog("Neutral Price = ", neutralPrice);
        }
        printInNextLine("=======================");
    }

    function printLog(string memory key, uint256 value) internal {
        string memory data = string(abi.encodePacked(key, Strings.toString(value)));
        printLine(data);
    }

    function printLine(string memory data) internal {
        vm.writeLine(path, data);
    }

    function printInNextLine(string memory data) internal {
        printLine("");
        printLine(data);
    }

    /**
     * @dev Resets all local states before each action.
     */
    modifier updateLocalStateAndPoolInterest() {
        _updateLocalFenwick();
        _fenwickAccrueInterest();
        _updatePoolState();

        _resetAndRecordReservesAndExchangeRate();

        _;
    }

    modifier useRandomActor(uint256 actorIndex_) {
        _actor = actors[constrictToRange(actorIndex_, 0, actors.length - 1)];

        _;

    }

    modifier useRandomLenderBucket(uint256 bucketIndex_) {
        uint256[] storage lenderBucketIndexes = touchedBuckets[_actor];

        if (lenderBucketIndexes.length < 3) {
            // if actor has touched less than three buckets, add a new bucket
            _lenderBucketIndex = constrictToRange(bucketIndex_, LENDER_MIN_BUCKET_INDEX, LENDER_MAX_BUCKET_INDEX);

            lenderBucketIndexes.push(_lenderBucketIndex);
        } else {
            // if actor has touched more than three buckets, reuse one of the touched buckets
            _lenderBucketIndex = lenderBucketIndexes[constrictToRange(bucketIndex_, 0, lenderBucketIndexes.length - 1)];
        }

        _;
    }

    /*****************************/
    /*** Pool Helper Functions ***/
    /*****************************/

    function _ensureQuoteAmount(address actor_, uint256 amount_) internal {
        uint256 normalizedActorBalance = _quote.balanceOf(actor_) * _pool.quoteTokenScale();
        if (amount_> normalizedActorBalance) {
            _quote.mint(actor_, amount_ - normalizedActorBalance);
        }
        _quote.approve(address(_pool), amount_);
    }

    function _updatePoolState() internal {
        _pool.updateInterest();
    }

    function _getKickSkipTime() internal returns (uint256) {
        return vm.envOr("SKIP_TIME_TO_KICK", uint256(200 days));
    }

    function _getKickReserveTime() internal returns (uint256) {
        return vm.envOr("SKIP_TIME_TO_KICK_RESERVE", uint256(24 hours));
    }

    function _repayBorrowerDebt(address borrower_, uint256 amount_) internal virtual;

    /**
     * @dev Ensure that error is an Pool expected error.
     */
    function _ensurePoolError(bytes memory err_) internal pure {
        bytes32 err = keccak256(err_);

        require(
            err == keccak256(abi.encodeWithSignature("InvalidAmount()")) ||
            err == keccak256(abi.encodeWithSignature("BucketBankruptcyBlock()")) ||
            err == keccak256(abi.encodeWithSignature("LUPBelowHTP()")) ||
            err == keccak256(abi.encodeWithSignature("InsufficientLiquidity()")) ||
            err == keccak256(abi.encodeWithSignature("RemoveDepositLockedByAuctionDebt()")) ||
            err == keccak256(abi.encodeWithSignature("NoClaim()")) ||
            err == keccak256(abi.encodeWithSignature("MoveToSameIndex()")) ||
            err == keccak256(abi.encodeWithSignature("DustAmountNotExceeded()")) ||
            err == keccak256(abi.encodeWithSignature("InvalidIndex()")) ||
            err == keccak256(abi.encodeWithSignature("InsufficientLP()")) || 
            err == keccak256(abi.encodeWithSignature("AuctionNotCleared()")) ||
            err == keccak256(abi.encodeWithSignature("TransferorNotApproved()")) ||
            err == keccak256(abi.encodeWithSignature("TransferToSameOwner()")) ||
            err == keccak256(abi.encodeWithSignature("NoAllowance()")) ||
            err == keccak256(abi.encodeWithSignature("InsufficientCollateral()")) ||
            err == keccak256(abi.encodeWithSignature("AuctionActive()")) ||
            err == keccak256(abi.encodeWithSignature("BorrowerUnderCollateralized()")) ||
            err == keccak256(abi.encodeWithSignature("NoDebt()")) ||
            err == keccak256(abi.encodeWithSignature("AmountLTMinDebt()")) ||
            err == keccak256(abi.encodeWithSignature("BorrowerOk()")) ||
            err == keccak256(abi.encodeWithSignature("LimitIndexExceeded()")) ||
            err == keccak256(abi.encodeWithSignature("PriceBelowLUP()")) ||
            err == keccak256(abi.encodeWithSignature("NoAuction()")) ||
            err == keccak256(abi.encodeWithSignature("TakeNotPastCooldown()")) ||
            err == keccak256(abi.encodeWithSignature("AuctionPriceGtBucketPrice()")) ||
            err == keccak256(abi.encodeWithSignature("AuctionNotClearable()")) ||
            err == keccak256(abi.encodeWithSignature("ReserveAuctionTooSoon()")) ||
            err == keccak256(abi.encodeWithSignature("NoReserves()")) ||
            err == keccak256(abi.encodeWithSignature("ZeroThresholdPrice()")) ||
            err == keccak256(abi.encodeWithSignature("NoReservesAuction()")),
            "Unexpected revert error"
        );
    }

    /**************************************/
    /*** Exchange Rate Helper Functions ***/
    /**************************************/

    /**
     * @dev Record the reserves and exchange rates before each action.
     */
    function _resetAndRecordReservesAndExchangeRate() internal {
        for (uint256 bucketIndex = LENDER_MIN_BUCKET_INDEX; bucketIndex <= LENDER_MAX_BUCKET_INDEX; bucketIndex++) {
            // reset the change flag before each action
            exchangeRateShouldNotChange[bucketIndex] = false;
            // record exchange rate before each action
            previousExchangeRate[bucketIndex] = _pool.bucketExchangeRate(bucketIndex);
            // record bankrupcy block before each action
            (,,uint256 bankruptcyTimestamp,,) = _pool.bucketInfo(bucketIndex);
            previousBankruptcy[bucketIndex] = bankruptcyTimestamp;
        }

        // reset the reserves before each action 
        increaseInReserves = 0;
        decreaseInReserves = 0;
        // record reserves before each action
        (previousReserves, , , , ) = _poolInfo.poolReservesInfo(address(_pool));

        // reset the bonds before each action
        increaseInBonds = 0;
        decreaseInBonds = 0;
        // record totalBondEscrowed before each action
        (previousTotalBonds, , , ) = _pool.reservesInfo();
    }

    /********************************/
    /*** Fenwick Helper Functions ***/
    /********************************/

    function _fenwickAdd(uint256 amount_, uint256 bucketIndex_) internal {
        fenwickDeposits[bucketIndex_] += amount_;
    }

    function _fenwickRemove(uint256 removedAmount_, uint256 bucketIndex_) internal {
        // removedAmount can be slightly greater than fenwickDeposits due to rounding in accrue interest
        fenwickDeposits[bucketIndex_] -= Maths.min(fenwickDeposits[bucketIndex_], removedAmount_);
    }

    function _fenwickAccrueInterest() internal {
        ( , , , , uint256 pendingFactor) = _poolInfo.poolLoansInfo(address(_pool));

        // poolLoansInfo returns 1e18 if no interest is pending or time elapsed... the contracts calculate 0 time elapsed which causes discrep
        if (pendingFactor == 1e18) return;

        // get TP of worst loan, pendingInflator and poolDebt
        uint256 maxThresholdPrice;
        uint256 pendingInflator;
        uint256 poolDebt;
        {
            (, poolDebt ,,) = _pool.debtInfo();

            (uint256 inflator, uint256 inflatorUpdate) = _pool.inflatorInfo();

            (, maxThresholdPrice,) =  _pool.loansInfo();
            maxThresholdPrice = Maths.wdiv(maxThresholdPrice, inflator);

            (uint256 interestRate, ) = _pool.interestRateInfo();

            pendingInflator = PoolCommons.pendingInflator(
                inflator,
                inflatorUpdate,
                interestRate
            );
        }

        // get HTP and deposit above HTP
        uint256 htp = Maths.wmul(maxThresholdPrice, pendingInflator);
        uint256 accrualIndex;

        if (htp > MAX_PRICE)      accrualIndex = 1;                          // if HTP is over the highest price bucket then no buckets earn interest
        else if (htp < MIN_PRICE) accrualIndex = MAX_FENWICK_INDEX;          // if HTP is under the lowest price bucket then all buckets earn interest
        else                      accrualIndex = _poolInfo.priceToIndex(htp);

        uint256 lupIndex = _pool.depositIndex(poolDebt);

        // accrual price is less of lup and htp, and prices decrease as index increases
        if (lupIndex > accrualIndex) accrualIndex = lupIndex;
        
        uint256 interestEarningDeposit = fenwickSumTillIndex(accrualIndex);

        if (interestEarningDeposit != 0) {
            uint256 utilization          = _pool.depositUtilization();
            uint256 lenderInterestMargin = PoolCommons.lenderInterestMargin(utilization);

            uint256 newInterest = Maths.wmul(
                lenderInterestMargin,
                Maths.wmul(pendingFactor - Maths.WAD, poolDebt)
            );

            // Cap lender factor at 10x the interest factor for borrowers
            uint256 scale = Maths.min(
                (newInterest * 1e18) / interestEarningDeposit,
                10 * (pendingFactor - Maths.WAD)
            ) + Maths.WAD;

            // simulate scale being applied to all deposits above HTP
            _fenwickMult(accrualIndex, scale);
        } 
    }

    function _fenwickMult(uint256 index_, uint256 scale_) internal {
        while (index_ > 0) {
            fenwickDeposits[index_] = Maths.wmul(fenwickDeposits[index_], scale_);

            index_--;
        }
    }
    
    // update local fenwick to pool fenwick before each action
    function _updateLocalFenwick() internal {
        for (uint256 bucketIndex = LENDER_MIN_BUCKET_INDEX; bucketIndex <= LENDER_MAX_BUCKET_INDEX; bucketIndex++) {
            (, , , uint256 deposits, ) = _pool.bucketInfo(bucketIndex);
            fenwickDeposits[bucketIndex] = deposits;
        }
    }

    /*********************************/
    /*** Auctions Helper Functions ***/
    /*********************************/

    /**
     * @dev Called by actions that can settle auctions in order to reset test state.
     */
    function _auctionSettleStateReset(address actor_) internal {
        (address kicker, , , , , , , , , ) = _pool.auctionInfo(actor_);

        // auction is settled if kicker is 0x
        bool auctionSettled = kicker == address(0);
        // reset alreadyTaken flag if auction is settled
        if (auctionSettled) alreadyTaken[actor_] = false;
    }

    function _getKickerBond(address kicker_) internal view returns (uint256 bond_) {
        (uint256 claimableBond, uint256 lockedBond) = _pool.kickerInfo(kicker_);
        bond_ = claimableBond + lockedBond;
    }

    function _updateCurrentTakeState(address borrower_, uint256 borrowerDebt_) internal {
        if (!alreadyTaken[borrower_]) {
            alreadyTaken[borrower_] = true;

            // **RE7**: Reserves increase by 7% of the loan quantity upon the first take.
            increaseInReserves += Maths.wmul(borrowerDebt_, 0.07 * 1e18);
            firstTake = true;

        } else firstTake = false;

        // reset taken flag in case auction was settled by take action
        _auctionSettleStateReset(borrower_);
    }

    function _recordSettleBucket(
        address borrower_,
        uint256 borrowerCollateralBefore_,
        uint256 kickTimeBefore_,
        uint256 auctionPrice_
    ) internal {
        (uint256 kickTimeAfter, , , , , ) = _poolInfo.auctionStatus(address(_pool), borrower_);

        // **CT2**: Keep track of bucketIndex when borrower is removed from auction to check collateral added into that bucket
        if (kickTimeBefore_ != 0 && kickTimeAfter == 0 && borrowerCollateralBefore_ % 1e18 != 0) {
            if (auctionPrice_ < MIN_PRICE) {
                buckets.add(7388);
                lenderDepositTime[borrower_][7388] = block.timestamp;
            } else if (auctionPrice_ > MAX_PRICE) {
                buckets.add(0);
                lenderDepositTime[borrower_][0] = block.timestamp;
            } else {
                uint256 bucketIndex = _indexOf(auctionPrice_);
                buckets.add(bucketIndex);
                lenderDepositTime[borrower_][bucketIndex] = block.timestamp;
            }
        }
    }

    /**********************************/
    /*** Fenwick External Functions ***/
    /**********************************/

    function fenwickSumTillIndex(uint256 index_) public view returns (uint256 sum_) {
        uint256[] memory depositBuckets = getBuckets();

        for (uint256 i = 0; i < depositBuckets.length; i++) {
            uint256 bucket = depositBuckets[i];
            if (bucket <= index_) {
                sum_ += fenwickDeposits[bucket];
            }
        }
    }

    function fenwickIndexForSum(uint256 debt_) public view returns (uint256) {
        uint256 minIndex = LENDER_MIN_BUCKET_INDEX;
        uint256 maxIndex = LENDER_MAX_BUCKET_INDEX;

        uint256[] memory depositBuckets = getBuckets();
        for (uint256 i = 0; i < depositBuckets.length; i++) {
            minIndex = Maths.min(minIndex, depositBuckets[i]);
            maxIndex = Maths.max(maxIndex, depositBuckets[i]);
        }

        while (debt_ != 0 && minIndex <= maxIndex) {
            if (fenwickDeposits[minIndex] >= debt_) return minIndex;

            debt_ -= fenwickDeposits[minIndex];

            minIndex += 1;
        }

        return MAX_FENWICK_INDEX;
    }

    function fenwickSumAtIndex(uint256 index_) public view returns(uint256) {
        return fenwickDeposits[index_];
    }

    function fenwickTreeSum() external view returns (uint256) {
        return fenwickSumTillIndex(fenwickDeposits.length - 1);    
    }

    /*************************************/
    /*** Test Utils External Functions ***/
    /*************************************/

    function getActorsCount() external view returns(uint256) {
        return actors.length;
    }

    function constrictToRange(
        uint256 x_,
        uint256 min_,
        uint256 max_
    ) pure public returns (uint256 result_) {
        require(max_ >= min_, "MAX_LESS_THAN_MIN");

        uint256 size = max_ - min_;

        if (size == 0) return min_;            // Using max would be equivalent as well.
        if (max_ != type(uint256).max) size++; // Make the max inclusive.

        // Ensure max is inclusive in cases where x != 0 and max is at uint max.
        if (max_ == type(uint256).max && x_ != 0) x_--; // Accounted for later.

        if (x_ < min_) x_ += size * (((min_ - x_) / size) + 1);

        result_ = min_ + ((x_ - min_) % size);

        // Account for decrementing x to make max inclusive.
        if (max_ == type(uint256).max && x_ != 0) result_++;
    }

    function getBuckets() public view returns(uint256[] memory) {
        return buckets.values();
    }

}
