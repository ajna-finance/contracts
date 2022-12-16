// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import { ERC20HelperContract } from './ERC20DSTestPlus.sol';

import 'src/base/PoolHelper.sol';

contract ERC20PoolLiquidationsKickWithDepositTest is ERC20HelperContract {

    address internal _borrower1;
    address internal _borrower2;
    address internal _borrower3;
    address internal _borrower4;
    address internal _borrower5;
    address internal _lender1;
    address internal _lender2;

    function setUp() external {
        _borrower1 = makeAddr("borrower1");
        _borrower2 = makeAddr("borrower2");
        _borrower3 = makeAddr("borrower3");
        _borrower4 = makeAddr("borrower4");
        _borrower5 = makeAddr("borrower5");
        _lender1   = makeAddr("lender1");
        _lender2   = makeAddr("lender2");

        _mintQuoteAndApproveTokens(_lender1, 150_000 * 1e18);
        _mintQuoteAndApproveTokens(_lender2, 150_000 * 1e18);

        _mintCollateralAndApproveTokens(_borrower1,  1_000 * 1e18);
        _mintCollateralAndApproveTokens(_borrower2, 1_000 * 1e18);
        _mintCollateralAndApproveTokens(_borrower3, 1_000 * 1e18);
        _mintCollateralAndApproveTokens(_borrower4, 1_000 * 1e18);
        _mintCollateralAndApproveTokens(_borrower5, 1_000 * 1e18);

        // Lender 1 adds Quote token accross 2 buckets
        _addInitialLiquidity(
            {
                from:   _lender1,
                amount: 50_000 * 1e18,
                index:  2500
            }
        );
        _addInitialLiquidity(
            {
                from:   _lender1,
                amount: 50_000 * 1e18,
                index:  2501
            }
        );

        _addInitialLiquidity(
            {
                from:   _lender1,
                amount: 1_000 * 1e18,
                index:  2502
            }
        );

        // all 5 borrowers draw debt from pool
        _drawDebt(
            {
                from:               _borrower1,
                borrower:           _borrower1,
                amountToBorrow:     20_000 * 1e18,
                limitIndex:         5000,
                collateralToPledge: 1_000 * 1e18,
                newLup:             3_863.654368867279344664 * 1e18
            }
        );
        _drawDebt(
            {
                from:               _borrower2,
                borrower:           _borrower2,
                amountToBorrow:     20_000 * 1e18,
                limitIndex:         5000,
                collateralToPledge: 1_000 * 1e18,
                newLup:             3_863.654368867279344664 * 1e18
            }
        );
        _drawDebt(
            {
                from:               _borrower3,
                borrower:           _borrower3,
                amountToBorrow:     20_000 * 1e18,
                limitIndex:         5000,
                collateralToPledge: 1_000 * 1e18,
                newLup:             3_844.432207828138682757 * 1e18
            }
        );
        _drawDebt(
            {
                from:               _borrower4,
                borrower:           _borrower4,
                amountToBorrow:     20_000 * 1e18,
                limitIndex:         5000,
                collateralToPledge: 1_000 * 1e18,
                newLup:             3_844.432207828138682757 * 1e18
            }
        );
        _drawDebt(
            {
                from:               _borrower5,
                borrower:           _borrower5,
                amountToBorrow:     20_000 * 1e18,
                limitIndex:         5000,
                collateralToPledge: 1_000 * 1e18,
                newLup:             3_825.305679430983794766 * 1e18
            }
        );

        // Lender 2 adds Quote token to top bucket
        _addLiquidity(
            {
                from:    _lender2,
                amount:  10_000 * 1e18,
                index:   2500,
                lpAward: 10_000 * 1e27,
                newLup:  3_844.432207828138682757 * 1e18
            }
        );

        /*****************************/
        /*** Assert pre-kick state ***/
        /*****************************/

        _assertPool(
            PoolParams({
                htp:                  20.019230769230769240 * 1e18,
                lup:                  3_844.432207828138682757 * 1e18,
                poolSize:             111_000 * 1e18,
                pledgedCollateral:    5_000 * 1e18,
                encumberedCollateral: 26.036654682669472623 * 1e18,
                poolDebt:             100_096.153846153846200000 * 1e18,
                actualUtilization:    0.901767151767151768 * 1e18,
                targetUtilization:    1e18,
                minDebtAmount:        2_001.923076923076924000 * 1e18,
                loans:                5,
                maxBorrower:          address(_borrower1),
                interestRate:         0.05 * 1e18,
                interestRateUpdate:   _startTime
            })
        );
        // assert balances
        assertEq(_quote.balanceOf(address(_pool)), 11_000 * 1e18);
        assertEq(_quote.balanceOf(_lender1),       49_000 * 1e18);
        assertEq(_quote.balanceOf(_lender2),       140_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower1),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower2),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower3),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower4),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower5),     20_000 * 1e18);

        // assert lender cannot remove desired amount of 10000 quote tokens as LUP moves below HTP
        _assertRemoveLiquidityLupBelowHtpRevert(
            {
                from:   _lender1,
                amount: 15_000 * 1e18,
                index:  2500
            }
        );
    }
    
    function testKickWithDepositAmountHigherThanAvailable() external {

        // Kick with deposit amount higher than deposit available (15000 vs 10000)

        _kickWithDeposit(
            {
                from:   _lender1,
                amount: 15_000 * 1e18,
                index:  2500
            }
        );

        /******************************/
        /*** Assert post-kick state ***/
        /******************************/

        _assertPool(
            PoolParams({
                htp:                  20.019230769230769240 * 1e18,
                lup:                  99836282890,
                poolSize:             96_000 * 1e18,
                pledgedCollateral:    5_000 * 1e18,
                encumberedCollateral: 1005109478498.225674630783521952 * 1e18,
                poolDebt:             100_346.394230769230815500 * 1e18,
                actualUtilization:    1.045274939903846154 * 1e18,
                targetUtilization:    1e18,
                minDebtAmount:        2_508.659855769230770388 * 1e18,
                loans:                4,
                maxBorrower:          address(_borrower5),
                interestRate:         0.05 * 1e18,
                interestRateUpdate:   _startTime
            })
        );
        // assert balances
        assertEq(_quote.balanceOf(address(_pool)), 2_005.769230769230772000 * 1e18);
        assertEq(_quote.balanceOf(_lender1),       57_994.230769230769228000 * 1e18);
        assertEq(_quote.balanceOf(_lender2),       140_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower1),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower2),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower3),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower4),     20_000 * 1e18);
        assertEq(_quote.balanceOf(_borrower5),     20_000 * 1e18);
        // assert lenders LPs in bucket used
        _assertLenderLpBalance(
            {
                lender:      _lender1,
                index:       2500,
                lpBalance:   35_000 * 1e27,
                depositTime: _startTime
            }
        );
        _assertLenderLpBalance(
            {
                lender:      _lender2,
                index:       2500,
                lpBalance:   10_000 * 1e27,
                depositTime: _startTime
            }
        );
        // assert bucket LPs
        _assertBucket(
            {
                index:        2500,
                lpBalance:    45_000 * 1e27,
                collateral:   0,
                deposit:      45_000 * 1e18,
                exchangeRate: 1 * 1e27
            }
        );
        // assert lender1 as a kicker
        _assertKicker(
            {
                kicker:    _lender1,
                claimable: 0,
                locked:    6_005.769230769230772000 * 1e18
            }
        );
        // assert kicked auction
        _assertAuction(
            AuctionParams({
                borrower:          _borrower1,
                active:            true,
                kicker:            _lender1,
                bondSize:          6_005.769230769230772000 * 1e18,
                bondFactor:        0.3 * 1e18,
                kickTime:          _startTime,
                kickMomp:          3_863.654368867279344664 * 1e18,
                totalBondEscrowed: 6_005.769230769230772000 * 1e18,
                auctionPrice:      123_636.939803752939029248 * 1e18,
                debtInAuction:     20_269.471153846153855500 * 1e18,
                thresholdPrice:    20.269471153846153855 * 1e18,
                neutralPrice:      21.020192307692307702 * 1e18
            })
        );
    }
}