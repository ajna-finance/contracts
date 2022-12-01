// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { ERC20HelperContract } from './ERC20DSTestPlus.sol';

import 'src/erc20/ERC20Pool.sol';

import 'src/base/interfaces/pool/IPoolErrors.sol';

import 'src/libraries/BucketMath.sol';
import './IERC20Merged.sol';

contract ERC20PoolMulticallTest is ERC20HelperContract {

    address internal _lender;

    function setUp() external {
        _lender    = makeAddr("lender");

        _mintQuoteAndApproveTokens(_lender,   200_000 * 1e18);
    }

    function testMulticallDepositQuoteToken() external {
        assertEq(_pool.depositSize(), 0);

        bytes[] memory callsToExecute = new bytes[](3);

        callsToExecute[0] = abi.encodeWithSignature(
            "addQuoteToken(uint256,uint256)",
            10_000 * 1e18,
            2550
        );

        callsToExecute[1] = abi.encodeWithSignature(
            "addQuoteToken(uint256,uint256)",
            10_000 * 1e18,
            2551
        );

        callsToExecute[2] = abi.encodeWithSignature(
            "addQuoteToken(uint256,uint256)",
            10_000 * 1e18,
            2552
        );

        changePrank(_lender);
        vm.expectEmit(true, true, false, true);
        emit AddQuoteToken(_lender, 2550, 10_000 * 1e18, BucketMath.MAX_PRICE);
        vm.expectEmit(true, true, false, true);
        emit Transfer(_lender, address(_pool), 10_000 * 1e18);
        vm.expectEmit(true, true, false, true);
        emit AddQuoteToken(_lender, 2551, 10_000 * 1e18, BucketMath.MAX_PRICE);
        vm.expectEmit(true, true, false, true);
        emit Transfer(_lender, address(_pool), 10_000 * 1e18);
        vm.expectEmit(true, true, false, true);
        emit AddQuoteToken(_lender, 2552, 10_000 * 1e18, BucketMath.MAX_PRICE);
        vm.expectEmit(true, true, false, true);
        emit Transfer(_lender, address(_pool), 10_000 * 1e18);                
        IERC20PoolMerged(address(_pool)).multicall(callsToExecute);


        _assertPoolPrices(
            {
                htp:      0,
                htpIndex: 0,
                hpb:      3_010.892022197881557845 * 1e18,
                hpbIndex: 2550,
                lup:      BucketMath.MAX_PRICE,
                lupIndex: 0
            }
        );

        // check balances
        assertEq(_quote.balanceOf(address(_pool)), 30_000 * 1e18);
        assertEq(_quote.balanceOf(_lender),        170_000 * 1e18);

        assertEq(_pool.depositSize(), 30_000 * 1e18);

        // check buckets
        _assertBucket(
            {
                index:        2550,
                lpBalance:    10_000 * 1e27,
                collateral:   0,
                deposit:      10_000 * 1e18,
                exchangeRate: 1 * 1e27
            }
        );
        _assertLenderLpBalance(
            {
                lender:      _lender,
                index:       2550,
                lpBalance:   10_000 * 1e27,
                depositTime: _startTime
            }
        );

        _assertBucket(
            {
                index:        2551,
                lpBalance:    10_000 * 1e27,
                collateral:   0,
                deposit:      10_000 * 1e18,
                exchangeRate: 1 * 1e27
            }
        );
        _assertLenderLpBalance(
            {
                lender:      _lender,
                index:       2551,
                lpBalance:   10_000 * 1e27,
                depositTime: _startTime
            }
        );

        _assertBucket(
            {
                index:        2552,
                lpBalance:    10_000 * 1e27,
                collateral:   0,
                deposit:      10_000 * 1e18,
                exchangeRate: 1 * 1e27
            }
        );
        _assertLenderLpBalance(
            {
                lender:      _lender,
                index:       2552,
                lpBalance:   10_000 * 1e27,
                depositTime: _startTime
            }
        );
    }

    function testMulticallRevertString() public {
        bytes[] memory callsToExecute = new bytes[](1);

        callsToExecute[0] = abi.encodeWithSignature(
            "borrow(uint256,uint256)",
            10_000 * 1e18,
            2550
        );

        changePrank(_lender);
        vm.expectRevert(IPoolErrors.LimitIndexReached.selector);
        IERC20PoolMerged(address(_pool)).multicall(callsToExecute);
    }


}
