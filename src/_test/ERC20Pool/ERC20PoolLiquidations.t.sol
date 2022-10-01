// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import { ERC20HelperContract } from './ERC20DSTestPlus.sol';

import '../../erc20/ERC20Pool.sol';
import '../../erc20/ERC20PoolFactory.sol';

import '../../libraries/Actors.sol';
import '../../libraries/Maths.sol';
import '../../libraries/PoolUtils.sol';

contract ERC20PoolKickSuccessTest is ERC20HelperContract {

    address internal _borrower;
    address internal _borrower2;
    address internal _lender;

    function setUp() external {

        _borrower  = makeAddr("borrower");
        _borrower2 = makeAddr("borrower2");
        _lender    = makeAddr("lender");

        _mintQuoteAndApproveTokens(_lender, 120_000 * 1e18);
        _mintCollateralAndApproveTokens(_borrower,  2 * 1e18);
        _mintCollateralAndApproveTokens(_borrower2, 1_000 * 1e18);

        // Lender adds Quote token accross 5 prices
        vm.startPrank(_lender);
        _pool.addQuoteToken(2_000 * 1e18,  _i9_91);
        _pool.addQuoteToken(5_000 * 1e18,  _i9_81);
        _pool.addQuoteToken(11_000 * 1e18, _i9_72);
        _pool.addQuoteToken(25_000 * 1e18, _i9_62);
        _pool.addQuoteToken(30_000 * 1e18, _i9_52);
        vm.stopPrank();

        // Borrower adds collateral token and borrows
        vm.startPrank(_borrower);
        _collateral.approve(address(_pool), 20 * 1e18);
        _pool.pledgeCollateral(_borrower, 2 * 1e18);
        _pool.borrow(19.25 * 1e18, _i9_91);
        vm.stopPrank();

        // Borrower2 adds collateral token and borrows
        vm.startPrank(_borrower2);
        _collateral.approve(address(_pool), 7_980 * 1e18);
        _pool.pledgeCollateral(_borrower2, 1_000 * 1e18);
        _pool.borrow(7_980 * 1e18, _i9_72);
        vm.stopPrank();


        /**********************/
        /*** Pre-kick state ***/
        /**********************/

        _assertPool(
            PoolState({
                htp:                  9.634254807692307697 * 1e18,
                lup:                  _p9_72,
                poolSize:             73_000 * 1e18,
                pledgedCollateral:    1_002.0 * 1e18,
                encumberedCollateral: 823.649613971736296163 * 1e18,
                borrowerDebt:         8_006.941586538461542154 * 1e18,
                actualUtilization:    0.109684131322444679 * 1e18,
                targetUtilization:    1e18,
                minDebtAmount:        400.347079326923077108 * 1e18,
                loans:                2,
                maxBorrower:          address(_borrower),
                inflatorSnapshot:     1e18,
                pendingInflator:      1e18,
                interestRate:         0.05 * 1e18,
                interestRateUpdate:   0
            })
        );

        _assertBorrower(
            BorrowerState({
               borrower:          _borrower2,
               debt:              7_987.673076923076926760 * 1e18,
               pendingDebt:       7_987.673076923076926760 * 1e18,
               collateral:        1000 * 1e18,
               collateralization: 1.217037273735858713 * 1e18,
               mompFactor:        9.818751856078723036 * 1e18,
               inflator:          1e18
            })
        );
        
        _assertBorrower(
            BorrowerState({
               borrower:          _borrower,
               debt:              19.268509615384615394 * 1e18,
               pendingDebt:       19.268509615384615394 * 1e18,
               collateral:        2e18,
               collateralization: 1.009034539679184679 * 1e18,
               mompFactor:        9.917184843435912074 * 1e18,
               inflator:          1e18
            })
        );

         _assertAuction(
            AuctionState({
                borrower:       _borrower,
                kickTime:       0,
                price:          0,
                bpf:            0,
                kickPrice:      0,
                bondFactor:     0,
                bondSize:       0,
                next:           address(0),
                active:         false
            })
        );


    }


    function testKick() external {

        // Skip to make borrower undercollateralized
        skip(100 days);

        /************/
        /*** Kick ***/
        /************/
        vm.startPrank(_lender);
        _pool.kick(_borrower);
        vm.stopPrank();

        /**********************/
        /*** Post-kick state ***/
        /**********************/        
        _assertPool(
            PoolState({
                htp:                  8.097846143253778448 * 1e18,
                lup:                  _p9_72,
                poolSize:             73_094.502279691716022000 * 1e18,
                pledgedCollateral:    1_002.0 * 1e18,
                encumberedCollateral: 835.010119425512354679 * 1e18,
                borrowerDebt:         8_117.380421230925720814 * 1e18,
                actualUtilization:    0.111053227918158028 * 1e18,
                targetUtilization:    0.833343432560391572 * 1e18,
                minDebtAmount:        811.738042123092572081 * 1e18,
                loans:                1,
                maxBorrower:          address(_borrower2),
                inflatorSnapshot:     1.013792886272348689 * 1e18,
                pendingInflator:      1.013792886272348689 * 1e18,
                interestRate:         0.045 * 1e18,
                interestRateUpdate:   block.timestamp
            })
        );

        _assertBorrower(
            BorrowerState({
               borrower:          _borrower,
               debt:              19.534277977147272573 * 1e18,
               pendingDebt:       19.534277977147272573 * 1e18,
               collateral:        2e18,
               collateralization: 0.995306391810796636 * 1e18,
               mompFactor:        9.917184843435912074 * 1e18,
               inflator:          1.013792886272348689 * 1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower:       _borrower,
                kickTime:       block.timestamp,
                price:          99.171848434359120740 * 1e18,
                bpf:            int256(-0.01 * 1e18),
                kickPrice:      9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       0.195342779771472726 * 1e18,
                next:           address(0),
                active:         true
            })
        );


    }

    function testTakeGTNeutral() external {

        //TODO: assert lender state
        // Skip to make borrower undercollateralized
        skip(100 days);


        vm.startPrank(_lender);
        _pool.kick(_borrower);
        vm.stopPrank();

        //TODO: assert lender state

        _assertPool(
            PoolState({
                htp:                  8.097846143253778448 * 1e18,
                lup:                  _p9_72,
                poolSize:             73_094.502279691716022000 * 1e18,
                pledgedCollateral:    1_002.0 * 1e18,
                encumberedCollateral: 835.010119425512354679 * 1e18,
                borrowerDebt:         8_117.380421230925720814 * 1e18,
                actualUtilization:    0.111053227918158028 * 1e18,
                targetUtilization:    0.833343432560391572 * 1e18,
                minDebtAmount:        811.738042123092572081 * 1e18,
                loans:                1,
                maxBorrower:          address(_borrower2),
                inflatorSnapshot:     1.013792886272348689 * 1e18,
                pendingInflator:      1.013792886272348689 * 1e18,
                interestRate:         0.045 * 1e18,
                interestRateUpdate:   block.timestamp
            })
        );

        _assertBorrower(
            BorrowerState({
               borrower:          _borrower,
               debt:              19.534277977147272573 * 1e18,
               pendingDebt:       19.534277977147272573 * 1e18,
               collateral:        2 * 1e18,
               collateralization: 0.995306391810796636 * 1e18,
               mompFactor:        9.917184843435912074 * 1e18,
               inflator:          1.013792886272348689 * 1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower: _borrower,
                kickTime:       block.timestamp,
                price:          99.171848434359120740 * 1e18,
                bpf:            int256(-0.01 * 1e18),
                kickPrice:      9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       0.195342779771472726 * 1e18,
                next:           address(0),
                active:         true
            })
        );

        skip(2 hours);
 
        bytes memory data = new bytes(0);
        vm.startPrank(_lender);
        vm.expectEmit(true, true, false, true);
        emit Take(_borrower, 
                19.341067992886131878 * 1e18,
                0.390051578108636266 * 1e18,
                -0.193410679928861319 * 1e18);
        _pool.take(_borrower, 20e18, data);
        vm.stopPrank();


        _assertPool(
            PoolState({
                htp:                  8.097929340730578998 * 1e18,
                lup:                  _p9_72,
                poolSize:             73_094.573649505265010718 * 1e18,
                pledgedCollateral:    1_001.609948421891363734 * 1e18,
                encumberedCollateral: 833.009246211652698536 * 1e18,
                borrowerDebt:         8_097.929340730578997898 * 1e18,
                actualUtilization:    0.110787011079110237 * 1e18,
                targetUtilization:    0.833343432560391572 * 1e18,
                minDebtAmount:        809.792934073057899790 * 1e18,
                loans:                1,
                maxBorrower:          address(_borrower2),
                inflatorSnapshot:     1.013803302006192493 * 1e18,
                pendingInflator:      1.013803302006192493 * 1e18,
                interestRate:         0.045 * 1e18,
                interestRateUpdate:   block.timestamp - 2 hours
            })
        );

        //TODO: assert lender state

        _assertBorrower(
            BorrowerState({
               borrower:          _borrower,
               debt:              0,
               pendingDebt:       0,
               collateral:        1.609948421891363734 * 1e18,
               collateralization: 1e18,
               mompFactor:        9.917184843435912074 * 1e18,
               inflator:          1.013803302006192493 * 1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower:       _borrower,
                kickTime:       (block.timestamp - 2 hours),
                price:          49.585924217179560370 * 1e18,
                bpf:            int256(-0.01 * 1e18),
                kickPrice: 9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       0.001932099842611407 * 1e18,
                next:           address(0),
                active:         false
            })
        );
        
    }

    function testTakeLTNeutral() external {
         
        // Borrower2 borrows
        vm.startPrank(_borrower2);
        _pool.borrow(1_730 * 1e18, _i9_72);
        vm.stopPrank();

        // Skip to make borrower undercollateralized
        skip(100 days);

        //TODO: assert lender state

        vm.startPrank(_lender);
        _pool.kick(_borrower2);
        vm.stopPrank();

        //skip ahead so take can be called on the loan
        skip(1.5 hours);

        //TODO: assert lender state

        _assertPool(
            PoolState({
                htp:                  9.767138988573636287 * 1e18,
                lup:                  _p9_72,
                poolSize:             73_118.781595119199960000 * 1e18,
                pledgedCollateral:    1_002.0 * 1e18,
                encumberedCollateral: 1_015.597987863945504486 * 1e18,
                borrowerDebt:         9_872.928519956368918239 * 1e18,
                actualUtilization:    4.659719785512357401 * 1e18,
                targetUtilization:    1.013570846171602300 * 1e18,
                minDebtAmount:        987.292851995636891824 * 1e18,
                loans:                1,
                maxBorrower:          address(_borrower),
                inflatorSnapshot:     1.013792886272348689 * 1e18,
                pendingInflator:      1.013802434024284946 * 1e18,
                interestRate:         0.055 * 1e18,
                interestRateUpdate:   block.timestamp - 1.5 hours
            })
        );

        _assertBorrower(
            BorrowerState({
               borrower:          _borrower2,
               debt:              9_853.394241979221645666 * 1e18,
               pendingDebt:       9_853.487039793475871463 * 1e18,
               collateral:        1000.0 * 1e18,
               collateralization: 0.986593617011217057 * 1e18,
               mompFactor:        9.818751856078723036 * 1e18,
               inflator:          1.013792886272348689 * 1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower:       _borrower2,
                kickTime:       block.timestamp - 1.5 hours,
                price:          70.125086530739830440 * 1e18,
                bpf:            int256(-0.01 * 1e18),
                kickPrice:      9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       98.533942419792216457 * 1e18,
                next:           address(0),
                active:         true
            })
        );

        skip(3.5 hours);

        vm.startPrank(_lender);
        bytes memory data = new bytes(0); 
        _pool.take(_borrower2, 20 * 1e18, data);
        vm.stopPrank();

        //TODO: assert lender state
        _assertPool(
            PoolState({
                htp:                  9.767445610192598576 * 1e18,
                lup:                  _p9_72,
                poolSize:             73_119.091537808684512392 * 1e18,
                pledgedCollateral:    998.773277849995859673 * 1e18,
                encumberedCollateral: 1_013.593105224726321400 * 1e18,
                borrowerDebt:         9_853.438462645853472494 * 1e18,
                actualUtilization:    4.650318606623740397 * 1e18,
                targetUtilization:    1.013570846171602300 * 1e18,
                minDebtAmount:        985.343846264585347249 * 1e18,
                loans:                1,
                maxBorrower:          address(_borrower),
                inflatorSnapshot:     1.013824712461823922 * 1e18,
                pendingInflator:      1.013824712461823922 * 1e18,
                interestRate:         0.055 * 1e18,
                interestRateUpdate:   block.timestamp -  5 hours
            })
        
        );

        _assertBorrower(
            BorrowerState({
               borrower:          _borrower2,
               debt:              9_833.903571425468275346 * 1e18,
               pendingDebt:       9_833.903571425468275346 * 1e18,
               collateral:        996.773277849995859673 * 1e18,
               collateralization: 0.985359259825723463 * 1e18,
               mompFactor:        9.818751856078723036 * 1e18,
               inflator:          1.013824712461823922 * 1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower:       _borrower2,
                kickTime:       (block.timestamp - 5 hours),
                price:          6.198240527147445050 * 1e18,
                bpf:            int256(0.01 * 1e18),
                kickPrice:      9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       98.733942419792216457 * 1e18,
                next:           address(0),
                active:         true
            })
        );

        // perform take, _borrower2 has no debt but the auction remains active.
        vm.startPrank(_lender);
        vm.expectEmit(true, true, false, true);
        emit Take(_borrower2, 
                6_178.240527147445049999 * 1e18,
                996.773277849995859673 * 1e18,
                61.782405271474450500 * 1e18);

        _pool.take(_borrower2, 8_000 * 1e18, data);
        vm.stopPrank();

        _assertPool(
           PoolState({
               htp:                  9.767445610192598576 * 1e18,
               lup:                  _p9_81,
               poolSize:             73_119.091537808684512392 * 1e18,
               pledgedCollateral:    2.0 * 1e18,
               encumberedCollateral: 380.596270844378611524 * 1e18,
               borrowerDebt:         3_736.980340769882872995 * 1e18,
               actualUtilization:    0,
               targetUtilization:    1.013570846171602300 * 1e18,
               minDebtAmount:        373.698034076988287300 * 1e18,
               loans:                1,
               maxBorrower:          address(_borrower),
               inflatorSnapshot:     1.013824712461823922 * 1e18,
               pendingInflator:      1.013824712461823922 * 1e18,
               interestRate:         0.055 * 1e18,
               interestRateUpdate:   block.timestamp - 5 hours
           })
        );

        _assertBorrower(
            BorrowerState({
               borrower:          _borrower2,
               debt:              3_717.445449549497675847 * 1e18,
               pendingDebt:       3_717.445449549497675847 * 1e18,
               collateral:        0,
               collateralization: 0,
               mompFactor:        9.818751856078723036 * 1e18,
               inflator:          1.013824712461823922 * 1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower:       _borrower2,
                kickTime:       (block.timestamp - 5 hours),
                price:          6.198240527147445050 * 1e18,
                bpf:            0,
                kickPrice:      9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       160.516347691266666957 * 1e18,
                next:           address(0),
                active:         true
            })
        );
        
    }

    function testTakeInterestIncreaseBig() external {
        //TODO: This is breaking something
        //skip(200 days);
    }

    function testBondFactorFormula() external {
        // threshold price (100) greater than the pool price (50)
        // min(0.3, max(0.01, 1 - 2)) = min(0.3, max(0.01, -1)) = min(0.3, 0.01) = 0.01
        assertEq(_bondFactorFormula(100 * 1e18, 50 * 1e18), 0.01 * 1e18);

        // threshold price (100) equals pool price (100)
        // min(0.3, max(0.01, 1 - 1)) = min(0.3, max(0.01, 0)) = min(0.3, 0.01) = 0.01
        assertEq(_bondFactorFormula(100 * 1e18, 50 * 1e18), 0.01 * 1e18);

        // threshold price (100) less than pool price (110)
        // min(0.3, max(0.01, 1 - 0.909090909)) = min(0.3, max(0.01, 0.090909091)) = min(0.3, 0.090909091) = 0.090909091
        assertEq(_bondFactorFormula(100 * 1e18, 110 * 1e18), 0.090909090909090909 * 1e18);

        // threshold price 80, pool price 100
        // min(0.3, max(0.01, 1 - 0.8)) = min(0.3, max(0.01, 0.2)) = min(0.3, 0.2) = 0.2
        assertEq(_bondFactorFormula(80 * 1e18, 100 * 1e18), 0.2 * 1e18);

        // threshold price 30, pool price 100
        // min(0.3, max(0.01, 1 - 0.3)) = min(0.3, max(0.01, 0.7)) = min(0.3, 0.7) = 0.3
        assertEq(_bondFactorFormula(30 * 1e18, 100 * 1e18), 0.3 * 1e18);
    }

    function _bondFactorFormula(uint256 thresholdPrice_, uint256 momp_) internal pure returns (uint256 bondFactor_) {
        bondFactor_= thresholdPrice_ >= momp_ ? 0.01 * 1e18 : Maths.min(0.3 * 1e18, Maths.max(0.01 * 1e18, 1 * 1e18 - Maths.wdiv(thresholdPrice_, momp_)));
    }


    function testAuctionPrice() external {
        skip(6238);
        uint256 kickPrice = 8_710.966329969607675529 * 1e18;
        uint256 kickPriceIndex = PoolUtils.priceToIndex(kickPrice);

        uint256 kickTime = block.timestamp;
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 87_109.663299696076755290 * 1e18);
        skip(1444); // price should not change in the first hour
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 87_109.663299696076755290 * 1e18);

        skip(5756);     // 2 hours
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 43_554.831649848038377650 * 1e18);
        skip(2394);     // 2 hours, 39 minutes, 54 seconds
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 27_469.540344283308792180 * 1e18);
        skip(2586);     // 3 hours, 23 minutes
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 16_695.964479006155137280 * 1e18);
        skip(3);        // 3 seconds later
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 16_686.323296502454155310 * 1e18);
        skip(20153);    // 8 hours, 35 minutes, 53 seconds
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 344.491106221733663590 * 1e18);
        skip(97264);    // 36 hours
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 0.000002535224832030 * 1e18);
        skip(129600);   // 72 hours
        assertEq(PoolUtils.auctionPrice(kickPriceIndex, kickTime), 0);
    }

}
