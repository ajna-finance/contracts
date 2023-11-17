// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { ERC20HelperContract } from './ERC20DSTestPlus.sol';

import 'src/libraries/helpers/PoolHelper.sol';

contract ERC20PoolLiquidationsArbTakeTest is ERC20HelperContract {

    address internal _borrower;
    address internal _borrower2;
    address internal _lender;
    address internal _lender1;
    address internal _taker;

    function setUp() external {
        _startTest();

        _borrower  = makeAddr("borrower");
        _borrower2 = makeAddr("borrower2");
        _lender    = makeAddr("lender");
        _lender1   = makeAddr("lender1");
        _taker     = makeAddr("taker");

        _mintQuoteAndApproveTokens(_lender,  120_000 * 1e18);
        _mintQuoteAndApproveTokens(_lender1, 120_000 * 1e18);

        _mintCollateralAndApproveTokens(_borrower,  4 * 1e18);
        _mintCollateralAndApproveTokens(_borrower2, 1_000 * 1e18);
        _mintCollateralAndApproveTokens(_lender1,   4 * 1e18);

        // Lender adds Quote token accross 5 prices
        _addInitialLiquidity({
            from:   _lender,
            amount: 2_000 * 1e18,
            index:  _i9_91
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 5_000 * 1e18,
            index:  _i9_81
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 11_000 * 1e18,
            index:  _i9_72
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 25_000 * 1e18,
            index:  _i9_62
        });
        _addInitialLiquidity({
            from:   _lender,
            amount: 30_000 * 1e18,
            index:  _i9_52
        });

        // first borrower pledge collateral and borrows
        _pledgeCollateral({
            from:     _borrower,
            borrower: _borrower,
            amount:   2 * 1e18
        });
        _borrow({
            from:       _borrower,
            amount:     19.25 * 1e18,
            indexLimit: _i9_91,
            newLup:     9.917184843435912074 * 1e18
        });

        // second borrower adds collateral and borrows
        _pledgeCollateral({
            from:     _borrower2,
            borrower: _borrower2,
            amount:   1_000 * 1e18
        });
        _borrow({
            from:       _borrower2,
            amount:     7_980 * 1e18,
            indexLimit: _i9_72,
            newLup:     9.721295865031779605 * 1e18
        });

        /*****************************/
        /*** Assert pre-kick state ***/
        /*****************************/

        _assertPool(
            PoolParams({
                htp:                  9.634254807692307697 * 1e18,
                lup:                  9.721295865031779605 * 1e18,
                poolSize:             73_000 * 1e18,
                pledgedCollateral:    1_002 * 1e18,
                encumberedCollateral: 823.649613971736296163 * 1e18,
                poolDebt:             8_006.941586538461542154 * 1e18,
                actualUtilization:    0,
                targetUtilization:    1e18,
                minDebtAmount:        400.347079326923077108 * 1e18,
                loans:                2,
                maxBorrower:          address(_borrower),
                interestRate:         0.05 * 1e18,
                interestRateUpdate:   _startTime
            })
        );
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.268509615384615394 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 1.009034539679184678 * 1e18
        });
        _assertBorrower({
            borrower:                  _borrower2,
            borrowerDebt:              7_987.673076923076926760 * 1e18,
            borrowerCollateral:        1_000 * 1e18,
            borrowert0Np:              8.880722076025322255 * 1e18,
            borrowerCollateralization: 1.217037273735858713 * 1e18
        });

        _assertReserveAuction({
            reserves:                   7.691586538461542154 * 1e18,
            claimableReserves :         7.691513538461542154 * 1e18,
            claimableReservesRemaining: 0,
            auctionPrice:               0,
            timeRemaining:              0
        });

        assertEq(_quote.balanceOf(_lender), 47_000 * 1e18);

        // should revert if there's no auction started
        _assertArbTakeNoAuctionRevert({
            from:     _lender,
            borrower: _borrower,
            index:    _i9_91
        });

        // Skip to make borrower undercollateralized
        skip(100 days);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            false,
                kicker:            address(0),
                bondSize:          0,
                bondFactor:        0,
                kickTime:          0,
                referencePrice:    0,
                totalBondEscrowed: 0,
                auctionPrice:      0,
                debtInAuction:     0,
                thresholdPrice:    9.767138988573636287 * 1e18,
                neutralPrice:      0
            })
        );
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.534277977147272574 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 0.995306391810796636 * 1e18
        });
        
        _kick({
            from:           _lender,
            borrower:       _borrower,
            debt:           19.534277977147272573 * 1e18,
            collateral:     2 * 1e18,
            bond:           0.218399867241391915 * 1e18,
            transferAmount: 0.218399867241391915 * 1e18
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.218399867241391915 * 1e18,
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp,
                referencePrice:    10.859138324780595900 * 1e18,
                totalBondEscrowed: 0.218399867241391915 * 1e18,
                auctionPrice:      2_779.939411143832550400 * 1e18,
                debtInAuction:     19.534277977147272574 * 1e18,
                thresholdPrice:    9.767138988573636287 * 1e18,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );
        _assertKicker({
            kicker:    _lender,
            claimable: 0,
            locked:    0.218399867241391915 * 1e18
        });
    }

    function testArbTakeCollateralRestrict() external tearDown {
        skip(6.5 hours);

        _assertLenderLpBalance({
            lender:      _taker,
            index:       _i9_91,
            lpBalance:   0,
            depositTime: 0
        });
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i9_91,
            lpBalance:   2_000 * 1e18,
            depositTime: _startTime
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   0,
            deposit:      2_010.430334387621616000 * 1e18,
            exchangeRate: 1.005215167193810808 * 1e18
        });
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.534930245606410328 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 0.995273158676181149 * 1e18
        });

        // add liquidity to accrue interest and update reserves before arb take
        _addLiquidityWithPenalty({
            from:        _lender1,
            amount:      1 * 1e18,
            amountAdded: 0.999876712328767123 * 1e18,
            index:       _i9_52,
            lpAward:     0.999873539625283938 * 1e18,
            newLup:      9.721295865031779605 * 1e18
        });

        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_000 * 1e18,
            collateral:   0,
            deposit:      2_010.436713693675662000 * 1e18,
            exchangeRate: 1.005218356846837831 * 1e18
        });
        _assertReserveAuction({
            reserves:                   24.296647707318004711 * 1e18,
            claimableReserves :         24.296574612213183994 * 1e18,
            claimableReservesRemaining: 0,
            auctionPrice:               0,
            timeRemaining:              0
        });
        
        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.218399867241391915 * 1e18, // should be the same after arb take, kicker will be rewarded with LP
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp - 6.5 hours,
                referencePrice:    10.859138324780595900 * 1e18,
                totalBondEscrowed: 0.218399867241391915 * 1e18,
                auctionPrice:      9.131410490052230040 * 1e18,
                debtInAuction:     19.534930245606410328 * 1e18,
                thresholdPrice:    9.767465122803205164 * 1e18,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.534930245606410328 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 0.995273158676181149 * 1e18
        });

        // Amount is restricted by the collateral in the loan
        _arbTake({
            from:             _taker,
            borrower:         _borrower,
            kicker:           _lender,
            index:            _i9_91,
            collateralArbed:  2 * 1e18,
            quoteTokenAmount: 18.262820980104460080 * 1e18,
            bondChange:       0.176128627037141836 * 1e18,
            isReward:         true,
            lpAwardTaker:     1.563390377884649324 * 1e18,
            lpAwardKicker:    0.175214296314306203 * 1e18
        });

        _assertLenderLpBalance({
            lender:      _taker,
            index:       _i9_91,
            lpBalance:   1.563390377884649324 * 1e18,
            depositTime: _startTime + 100 days + 6.5 hours
        });
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i9_91,
            lpBalance:   2_000.175214296314306203 * 1e18, // rewarded with LP in bucket
            depositTime: _startTime + 100 days + 6.5 hours
        });
        _assertBucket({
            index:        _i9_91,
            lpBalance:    2_001.738604674198955527 * 1e18,
            collateral:   2 * 1e18,
            deposit:      1_992.350021340608343756 * 1e18,
            exchangeRate: 1.005218356846837832 * 1e18
        });
        // reserves should remain the same after arb take
        _assertReserveAuction({
            reserves:                   24.331717605849220576 * 1e18,
            claimableReserves :         24.331644528831092212 * 1e18,
            claimableReservesRemaining: 0,
            auctionPrice:               0,
            timeRemaining:              0
        });
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              1.483307791070307952 * 1e18,
            borrowerCollateral:        0,
            borrowert0Np:              0,
            borrowerCollateralization: 0
        });
        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.218399867241391915 * 1e18, // bond size remains the same, kicker was rewarded with LP
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp - 6.5 hours,
                referencePrice:    10.859138324780595900 * 1e18,
                totalBondEscrowed: 0.218399867241391915 * 1e18,
                auctionPrice:      9.131410490052230040 * 1e18,
                debtInAuction:     1.483307791070307952 * 1e18,
                thresholdPrice:    0,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );

        // Arb take should fail on an auction without any remaining collateral to auction
        _assertArbTakeInsufficentCollateralRevert({
            from:     _taker,
            borrower: _borrower,
            index:    _i9_91
        });
    }

    function testArbTakeDebtRestrict() external tearDown {
        skip(5 hours);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.218399867241391915 * 1e18,
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp - 5 hours,
                referencePrice:    10.859138324780595900 * 1e18,
                totalBondEscrowed: 0.218399867241391915 * 1e18,
                auctionPrice:      15.357140694590170132 * 1e18,
                debtInAuction:     19.534277977147272574 * 1e18,
                thresholdPrice:    9.767389860091370755 * 1e18,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );

        _addLiquidity({
            from:    _lender,
            amount:  25_000 * 1e18,
            index:   _i1505_26,
            lpAward: 25_000 * 1e18,
            newLup:  1_505.263728469068226832 * 1e18
        });
        
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.534779720182741511 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 154.111154569495905655 * 1e18
        });

        // Amount is restricted by the debt in the loan
        _arbTake({
            from:             _taker,
            borrower:         _borrower,
            kicker:           _lender,
            index:            _i1505_26,
            collateralArbed:  1.293728839166329275 * 1e18,
            quoteTokenAmount: 19.867975803726136451 * 1e18,
            bondChange:       0.218399867241391915 * 1e18,
            isReward:         false,
            lpAwardTaker:     1_927.535120267742172688 * 1e18,
            lpAwardKicker:    0
        });

        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              0,
            borrowerCollateral:        0.706271160833670725 * 1e18,
            borrowert0Np:              0,
            borrowerCollateralization: 1 * 1e18
        });
        _assertLenderLpBalance({
            lender:      _taker,
            index:       _i1505_26,
            lpBalance:   1_927.535120267742172688 * 1e18,
            depositTime: block.timestamp
        });
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i1505_26,
            lpBalance:   25_000 * 1e18,
            depositTime: block.timestamp
        });
        _assertBucket({
            index:        _i1505_26,
            lpBalance:    26_927.535120267742172688 * 1e18,
            collateral:   1.293728839166329275 * 1e18,
            deposit:      24_980.132024196273863537 * 1e18,
            exchangeRate: 1.000000000000000001 * 1e18
        });
        _assertReserveAuction({
            reserves:                   24.839094252057628878 * 1e18,
            claimableReserves :         24.838996177874184714 * 1e18,
            claimableReservesRemaining: 0,
            auctionPrice:               0,
            timeRemaining:              0
        });
    }

    function testArbTakeDepositRestrict() external tearDown {
        skip(5 hours);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.218399867241391915 * 1e18,
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp - 5 hours,
                referencePrice:    10.859138324780595900 * 1e18,
                totalBondEscrowed: 0.218399867241391915 * 1e18,
                auctionPrice:      15.357140694590170132 * 1e18,
                debtInAuction:     19.534277977147272574 * 1e18,
                thresholdPrice:    9.767389860091370755 * 1e18,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );

        _addLiquidity({
            from:    _lender,
            amount:  15.0 * 1e18,
            index:   _i1505_26,
            lpAward: 15.0 * 1e18,
            newLup:  9.721295865031779605 * 1e18
        });

        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.534779720182741511 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 0.995280827762601466 * 1e18
        });

        // Amount is restricted by the deposit in the bucket
        _arbTake({
            from:             _taker,
            borrower:         _borrower,
            kicker:           _lender,
            index:            _i1505_26,
            collateralArbed:  0.976744323589092376 * 1e18,
            quoteTokenAmount: 14.999999999999999988 * 1e18,
            bondChange:       0.167705098312484220 * 1e18,
            isReward:         false,
            lpAwardTaker:     1_455.257802286715257980 * 1e18,
            lpAwardKicker:    0
        });

        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.050694768928907695 * 1e18,
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp - 5 hours,
                referencePrice:    10.859138324780595900 * 1e18,
                totalBondEscrowed: 0.050694768928907695 * 1e18,
                auctionPrice:      15.357140694590170132 * 1e18,
                debtInAuction:     4.786337367651467854 * 1e18,
                thresholdPrice:    4.677557601673566259 * 1e18,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );
        _assertBucket({
            index:        _i1505_26,
            lpBalance:    1_470.257802286715257980 * 1e18,
            collateral:   0.976744323589092376 * 1e18,
            deposit:      0.000000000000000012 * 1e18,
            exchangeRate: 1.000000000000000001 * 1e18
        });
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              4.786337367651467854 * 1e18,
            borrowerCollateral:        1.023255676410907624 * 1e18,
            borrowert0Np:              5.129638348220312523 * 1e18,
            borrowerCollateralization: 2.078284586287859426  * 1e18
        });
        _assertLenderLpBalance({
            lender:      _taker,
            index:       _i1505_26,
            lpBalance:   1_455.257802286715257980 * 1e18,
            depositTime: block.timestamp
        });
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i1505_26,
            lpBalance:   15.0 * 1e18,
            depositTime: block.timestamp
        });
    }

    function testArbTakeGTNeutralPrice() external tearDown {
        skip(3 hours);

        _addLiquidity({
            from:    _lender,
            amount:  1_000 * 1e18,
            index:   _i10016,
            lpAward: 1_000 * 1e18,
            newLup:  9.721295865031779605 * 1e18
        });

        _assertLenderLpBalance({
            lender:      _taker,
            index:       _i10016,
            lpBalance:   0,
            depositTime: 0
        });
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i10016,
            lpBalance:   1_000 * 1e18,
            depositTime: block.timestamp
        });
        _assertBucket({
            index:        _i10016,
            lpBalance:    1_000 * 1e18,
            collateral:   0,
            deposit:      1_000 * 1e18,
            exchangeRate: 1.0 * 1e18
        });
        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.218399867241391915 * 1e18,
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp - 3 hours,
                referencePrice:    10.859138324780595900 * 1e18,
                totalBondEscrowed: 0.218399867241391915 * 1e18,
                auctionPrice:      30.714281389180340260 * 1e18,
                debtInAuction:     19.534579021422084350 * 1e18,
                thresholdPrice:    9.767289510711042175 * 1e18,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.534579021422084350 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 0.995291053303086302 * 1e18
        });

        _arbTake({
            from:             _taker,
            borrower:         _borrower,
            kicker:           _lender,
            index:            _i10016,
            collateralArbed:  0.646857773749979766 * 1e18,
            quoteTokenAmount: 19.867771681735630739 * 1e18,
            bondChange:       0.218399867241391915 * 1e18,
            isReward:         false,
            lpAwardTaker:     6_459.384147131214782628 * 1e18,
            lpAwardKicker:    0
        });

        _assertLenderLpBalance({
            lender:      _taker,
            index:       _i10016,
            lpBalance:   6_459.384147131214782628 * 1e18, // arb taker was rewarded LPBs in arbed bucket
            depositTime: _startTime + 100 days + 3 hours
        });
        _assertLenderLpBalance({
            lender:      _lender,
            index:       _i10016,
            lpBalance:   1_000 * 1e18,
            depositTime: _startTime + 100 days + 3 hours
        });
        _assertKicker({
            kicker:    _lender,
            claimable: 0,
            locked:    0 // kicker was penalized
        });
        _assertBucket({
            index:        _i10016,
            lpBalance:    7_459.384147131214782628 * 1e18,       // LP balance in arbed bucket increased with LP awarded for arb taker
            collateral:   0.646857773749979766 * 1e18,        // arbed collateral added to the arbed bucket
            deposit:      980.132228318264369235 * 1e18,      // quote token amount is diminished in arbed bucket
            exchangeRate: 1.000000000000000001 * 1e18
        });
        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            false,
                kicker:            address(0),
                bondSize:          0,
                bondFactor:        0,
                kickTime:          0,
                referencePrice:    0,
                totalBondEscrowed: 0,
                auctionPrice:      0,
                debtInAuction:     0,
                thresholdPrice:    0,
                neutralPrice:      0
            })
        );
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              0,
            borrowerCollateral:        1.353142226250020234 * 1e18,
            borrowert0Np:              0,
            borrowerCollateralization: 1 * 1e18
        });
    }

    function testArbTakeReverts() external tearDown {
        // should revert if taken from same block when kicked
        _assertArbTakeAuctionNotTakeableRevert({
            from:     _taker,
            borrower: _borrower,
            index:    _i9_62
        });

        // should revert if borrower not auctioned
        _assertArbTakeNoAuction({
            from:     _lender,
            borrower: _borrower2,
            index:    _i9_91
        });

        skip(2.5 hours);

        _assertAuction(
            AuctionParams({
                borrower:          _borrower,
                active:            true,
                kicker:            _lender,
                bondSize:          0.218399867241391915 * 1e18,
                bondFactor:        0.011180339887498948 * 1e18,
                kickTime:          block.timestamp - 2.5 hours,
                referencePrice:    10.859138324780595900 * 1e18, 
                totalBondEscrowed: 0.218399867241391915 * 1e18,
                auctionPrice:      36.525641960208920284 * 1e18,
                debtInAuction:     19.534277977147272574 * 1e18,
                thresholdPrice:    9.767264423527051292 * 1e18,
                neutralPrice:      10.859138324780595900 * 1e18
            })
        );
        _assertBorrower({
            borrower:                  _borrower,
            borrowerDebt:              19.534528847054102585 * 1e18,
            borrowerCollateral:        2 * 1e18,
            borrowert0Np:              10.711397240820015878 * 1e18,
            borrowerCollateralization: 0.995293609704622698 * 1e18
        });

        // borrower cannot repay amidst auction
        _assertRepayAuctionActiveRevert({
            from:      _borrower,
            maxAmount: 10 * 1e18
        });

        // should revert if bucket deposit is 0
        _assertArbTakeAuctionInsufficientLiquidityRevert({
            from:     _taker,
            borrower: _borrower,
            index:    _i100_33
        });

        // should revert if auction price is greater than the bucket price
        _assertArbTakeAuctionPriceGreaterThanBucketPriceRevert({
            from:     _taker,
            borrower: _borrower,
            index:    _i9_91
        });

        skip(4 hours);

        // 10 borrowers draw debt to enable the min debt check
        for (uint i=0; i<10; ++i) {
            _anonBorrowerDrawsDebt(1_000 * 1e18, 6_000 * 1e18, MAX_FENWICK_INDEX);
        }

        // should revert if auction leaves borrower with debt under minimum pool debt
        _assertArbTakeDebtUnderMinPoolDebtRevert({
            from:     _taker,
            borrower: _borrower,
            index:    _i9_91
        });

        // ensure zero bid reverts
        skip(3 days);
        _assertArbTakeZeroBidRevert({
            from:     _taker,
            borrower: _borrower,
            index:    _i9_52
        });
    }
}
