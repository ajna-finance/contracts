// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import { ERC721HelperContract } from "./ERC721DSTestPlus.sol";

import '../../erc721/ERC721Pool.sol';
import '../../erc721/ERC721PoolFactory.sol';

import '../../libraries/Actors.sol';
import '../../libraries/Maths.sol';
import '../../libraries/PoolUtils.sol';


contract ERC721PoolKickSuccessTest is ERC721HelperContract {

    address internal _borrower;
    address internal _borrower2;
    address internal _lender;

    function setUp() external {

        _borrower  = makeAddr("borrower");
        _borrower2 = makeAddr("borrower2");
        _lender    = makeAddr("lender");


        // deploy collection pool
        ERC721Pool collectionPool = _deployCollectionPool();

        // deploy subset pool
        uint256[] memory subsetTokenIds = new uint256[](6);
        subsetTokenIds[0] = 1;
        subsetTokenIds[1] = 3;
        subsetTokenIds[2] = 5;
        subsetTokenIds[3] = 51;
        subsetTokenIds[4] = 53;
        subsetTokenIds[5] = 73;
        _pool = _deploySubsetPool(subsetTokenIds);

        address[] memory _poolAddresses = new address[](1);
        _poolAddresses[0] = address(_pool);

       _mintAndApproveQuoteTokens(_lender, 120_000 * 1e18);
       _mintAndApproveQuoteTokens(_borrower, 100 * 1e18);
       _mintAndApproveQuoteTokens(_borrower2, 8_000 * 1e18);

       _mintAndApproveCollateralTokens(_borrower, 6);
       _mintAndApproveCollateralTokens(_borrower2, 74);

       vm.prank(_borrower);
       _quote.approve(address(_pool), 200_000 * 1e18);
       vm.stopPrank();

       vm.prank(_borrower2);
       _quote.approve(address(_pool), 200_000 * 1e18);
       vm.stopPrank();

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
       uint256[] memory tokenIdsToAdd = new uint256[](2);
       tokenIdsToAdd[0] = 1;
       tokenIdsToAdd[1] = 3;
       _pool.pledgeCollateral(_borrower, tokenIdsToAdd);
       _pool.borrow(19.8 * 1e18, _i9_91);
       vm.stopPrank();
        

       // Borrower2 adds collateral token and borrows
       vm.startPrank(_borrower2);
       tokenIdsToAdd = new uint256[](3);
       tokenIdsToAdd[0] = 51;
       tokenIdsToAdd[1] = 53;
       tokenIdsToAdd[2] = 73;
       _pool.pledgeCollateral(_borrower2, tokenIdsToAdd);
       _pool.borrow(15 * 1e18, _i9_72);
       vm.stopPrank();

       ///**********************/
       ///*** Pre-kick state ***/
       ///**********************/

       _assertPool(
           PoolState({
               htp:                  9.909519230769230774 * 1e18,
               lup:                  _p9_91,
               poolSize:             73_000 * 1e18,
               pledgedCollateral:    5.0 * 1e18,
               encumberedCollateral: 3.512434434608473285 * 1e18,
               borrowerDebt:         34.833461538461538478 * 1e18,
               actualUtilization:    0.000477170706006322 * 1e18,
               targetUtilization:    1e18,
               minDebtAmount:        1.741673076923076924 * 1e18,
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
              borrower:          _borrower,
              debt:              19.819038461538461548 * 1e18,
              pendingDebt:       19.819038461538461548 * 1e18,
              collateral:        2e18,
              collateralization: 1.000773560501591181 * 1e18,
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
               referencePrice: 0,
               bondFactor:     0,
               bondSize:       0,
               next:           address(0),
               active:         false
           })
       );

    }


    function testSubsetKick() external {

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
                htp:                  5.073838435622668201 * 1e18,
                lup:                  _p9_91,
                poolSize:             73_000.0 * 1e18,
                pledgedCollateral:    5.0 * 1e18,
                encumberedCollateral: 3.560881043304109325 * 1e18,
                borrowerDebt:         35.313915511933770677 * 1e18,
                actualUtilization:    0.000483752267286764 * 1e18,
                targetUtilization:    0.712176208660821865 * 1e18,
                minDebtAmount:        3.531391551193377068 * 1e18,
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
               debt:              19.819038461538461548 * 1e18,
               pendingDebt:       19.819038461538461548 * 1e18,
               collateral:        2e18,
               collateralization: 1.000773560501591181 * 1e18,
               mompFactor:        9.917184843435912074 * 1e18,
               inflator:          1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower:       _borrower,
                kickTime:       block.timestamp,
                price:          99.171848434359120740 * 1e18,
                bpf:            int256(-0.01 * 1e18),
                referencePrice: 9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       0.200924002050657661 * 1e18,
                next:           address(0),
                active:         true
            })
        );
    }

    function skipSubsetTakeGTNeutral() external {

        //TODO: assert lender state
        // Skip to make borrower undercollateralized
        skip(100 days);


        vm.startPrank(_lender);
        _pool.kick(_borrower);
        vm.stopPrank();

        //TODO: assert lender state

        _assertPool(
            PoolState({
                htp:                  5.073838435622668201 * 1e18,
                lup:                  _p9_91,
                poolSize:             73_000.0 * 1e18,
                pledgedCollateral:    5.0 * 1e18,
                encumberedCollateral: 3.560881043304109325 * 1e18,
                borrowerDebt:         35.313915511933770677 * 1e18,
                actualUtilization:    0.000483752267286764 * 1e18,
                targetUtilization:    0.712176208660821865 * 1e18,
                minDebtAmount:        3.531391551193377068 * 1e18,
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
               debt:              19.819038461538461548 * 1e18,
               pendingDebt:       19.819038461538461548 * 1e18,
               collateral:        2 * 1e18,
               collateralization: 1.000773560501591181 * 1e18,
               mompFactor:        9.917184843435912074 * 1e18,
               inflator:          1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower: _borrower,
                kickTime:       block.timestamp,
                price:          99.171848434359120740 * 1e18,
                bpf:            int256(-0.01 * 1e18),
                referencePrice: 9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       0.200924002050657661 * 1e18,
                next:           address(0),
                active:         true
            })
        );

        skip(2 hours);
 
        bytes memory data = new bytes(0);
        uint256[] memory tokenIdsToTake = new uint256[](2);
        tokenIdsToTake[0] = 1;
        tokenIdsToTake[1] = 3;
        vm.startPrank(_lender);
        _pool.take(_borrower, tokenIdsToTake, data);
        vm.stopPrank();


        _assertPool(
           PoolState({
               htp:                  5.073890564367530700 * 1e18,
               lup:                  _p9_91,
               poolSize:             73_000.000326534457845000* 1e18,
               pledgedCollateral:    3.0 * 1e18,
               encumberedCollateral: 1.534878287882036215 * 1e18,
               borrowerDebt:         15.221671693102592102 * 1e18,
               actualUtilization:    0.000208516049657739 * 1e18,
               targetUtilization:    0.712176208660821865 * 1e18,
               minDebtAmount:        1.522167169310259210 * 1e18,
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
              collateral:        0,
              collateralization: 1e18,
              mompFactor:        9.782158751910768707 * 1e18,
              inflator:          1.013803302006192493 * 1e18
           })
        );

        _assertAuction(
           AuctionState({
               borrower:       _borrower,
               kickTime:       (block.timestamp - 2 hours),
               price:          49.585924217179560370 * 1e18,
               bpf:            int256(0 * 1e18),
               referencePrice: 9.917184843435912074 * 1e18,
               bondFactor:     0.01 * 1e18,
               bondSize:       0.200924002050657661 * 1e18,
               next:           address(0),
               active:         false
           })
        );
    }

    function skipSubsetTakeLTNeutral() external {

        // Skip to make borrower undercollateralized
        skip(100 days);

        //TODO: assert lender state

        vm.startPrank(_lender);
        _pool.kick(_borrower);
        vm.stopPrank();

        //TODO: assert lender state

        _assertPool(
            PoolState({
                htp:                  5.073838435622668201 * 1e18,
                lup:                  _p9_91,
                poolSize:             73_000.0 * 1e18,
                pledgedCollateral:    5.0 * 1e18,
                encumberedCollateral: 3.560881043304109325 * 1e18,
                borrowerDebt:         35.313915511933770677 * 1e18,
                actualUtilization:    0.000483752267286764 * 1e18,
                targetUtilization:    0.712176208660821865 * 1e18,
                minDebtAmount:        3.531391551193377068 * 1e18,
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
               debt:              19.819038461538461548 * 1e18,
               pendingDebt:       19.819038461538461548 * 1e18,
               collateral:        2 * 1e18,
               collateralization: 1.000773560501591181 * 1e18,
               mompFactor:        9.917184843435912074 * 1e18,
               inflator:          1e18
            })
        );

        _assertAuction(
            AuctionState({
                borrower: _borrower,
                kickTime:       block.timestamp,
                price:          99.171848434359120740 * 1e18,
                bpf:            int256(-0.01 * 1e18),
                referencePrice: 9.917184843435912074 * 1e18,
                bondFactor:     0.01 * 1e18,
                bondSize:       0.200924002050657661 * 1e18,
                next:           address(0),
                active:         true
            })
        );
        skip(5 hours);
 

        vm.startPrank(_lender);
        bytes memory data = new bytes(0);
        uint256[] memory tokenIdsToTake = new uint256[](2);
        tokenIdsToTake[0] = 1;
        tokenIdsToTake[1] = 3;

        vm.expectEmit(true, true, false, true);
        emit Take(_borrower2, 
                20.0 * 1e18,
                tokenIdsToTake,
                0);
        _pool.take(_borrower, tokenIdsToTake, data);
        vm.stopPrank();

        //TODO: assert lender state
    //     _assertPool(
    //         PoolState({
    //             htp:                  9.767445610192598576 * 1e18,
    //             lup:                  _p9_72,
    //             poolSize:             73_119.091537808684512392 * 1e18,
    //             pledgedCollateral:    998.773277849995859673 * 1e18,
    //             encumberedCollateral: 1_013.572531835871918275* 1e18,
    //             borrowerDebt:         9_853.238462645853472494 * 1e18,
    //             actualUtilization:    4.650224216860730195 * 1e18,
    //             targetUtilization:    1.013570846171602300 * 1e18,
    //             minDebtAmount:        985.323846264585347249 * 1e18,
    //             loans:                1,
    //             maxBorrower:          address(_borrower),
    //             inflatorSnapshot:     1.013824712461823922 * 1e18,
    //             pendingInflator:      1.013824712461823922 * 1e18,
    //             interestRate:         0.055 * 1e18,
    //             interestRateUpdate:   block.timestamp - 5 hours
    //         })
    //     );

    //     _assertBorrower(
    //         BorrowerState({
    //            borrower:          _borrower2,
    //            debt:              9_833.703571425468277820 * 1e18,
    //            pendingDebt:       9_833.703571425468277820 * 1e18,
    //            collateral:        996.773277849995859673 * 1e18,
    //            collateralization: 0.985379300276458401 * 1e18,
    //            mompFactor:        9.818751856078723036 * 1e18,
    //            inflator:          1e18
    //         })
    //     );

    //     _assertAuction(
    //         AuctionState({
    //             borrower:       _borrower2,
    //             kickTime:       (block.timestamp - 5 hours),
    //             price:          6.198240527147445050 * 1e18,
    //             bpf:            0,
    //             referencePrice: 9.917184843435912074 * 1e18,
    //             bondFactor:     0.01 * 1e18,
    //             bondSize:       98.533942419792216457 * 1e18,
    //             next:           address(0),
    //             active:         true
    //         })
    //     );

    //     // perform take, _borrower2 has no debt but the auction remains active.
    //     vm.startPrank(_lender);

    //     vm.expectEmit(true, true, false, true);

    //     emit Take(_borrower2, 
    //             6_178.240527147445049999 * 1e18,
    //             996.773277849995859673 * 1e18,
    //             0);

    //     _pool.take(_borrower2, 8_000 * 1e18, data);
    //     vm.stopPrank();

    //     _assertPool(
    //         PoolState({
    //             htp:                  9.767445610192598576 * 1e18,
    //             lup:                  _p9_81,
    //             poolSize:             73_119.091537808684512392 * 1e18,
    //             pledgedCollateral:    2.0 * 1e18,
    //             encumberedCollateral: 374.283614594378611622* 1e18,
    //             borrowerDebt:         3_674.997935498408422495 * 1e18,
    //             actualUtilization:    0.0 * 1e18,
    //             targetUtilization:    1.013570846171602300 * 1e18,
    //             minDebtAmount:        367.499793549840842250 * 1e18,
    //             loans:                1,
    //             maxBorrower:          address(_borrower),
    //             inflatorSnapshot:     1.013824712461823922 * 1e18,
    //             pendingInflator:      1.013824712461823922 * 1e18,
    //             interestRate:         0.055 * 1e18,
    //             interestRateUpdate:   block.timestamp - 5 hours
    //         })
    //     );

    //     _assertBorrower(
    //         BorrowerState({
    //            borrower:          _borrower2,
    //            debt:              3_791.411168587791307368 * 1e18,
    //            pendingDebt:       3_791.411168587791307368 * 1e18,
    //            collateral:        0 * 1e18,
    //            collateralization: 1e18,
    //            mompFactor:        9.818751856078723036 * 1e18,
    //            inflator:          1e18
    //         })
    //     );

    //     _assertAuction(
    //         AuctionState({
    //             borrower:       _borrower2,
    //             kickTime:       (block.timestamp - 5 hours),
    //             price:          6.198240527147445050 * 1e18,
    //             bpf:            0,
    //             referencePrice: 9.917184843435912074 * 1e18,
    //             bondFactor:     0.01 * 1e18,
    //             bondSize:       98.533942419792216457 * 1e18,
    //             next:           address(0),
    //             active:         true
    //         })
    //     );
        
    // }
    }
}