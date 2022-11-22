// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "@std/Test.sol";

import { ERC20Pool }        from 'src/erc20/ERC20Pool.sol';
import { ERC20PoolFactory } from 'src/erc20/ERC20PoolFactory.sol';

import 'src/base/PoolInfoUtils.sol';
import "./BalancerUniswapExample.sol";
import "./UniswapTakeExample.sol";

contract ERC20TakeWithExternalLiquidityTest is Test {
    address constant WETH     = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC     = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint24  constant POOL_FEE = 3000;

    IWETH  private weth = IWETH(WETH);
    IERC20 private usdc = IERC20(USDC);

    ERC20Pool internal _ajnaPool;

    address internal _borrower;
    address internal _borrower2;
    address internal _lender;
    address internal _lender1;

    function setUp() external {
        // create an Ajna pool
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        _ajnaPool = ERC20Pool(new ERC20PoolFactory().deployPool(WETH, USDC, 0.05 * 10**18));

        // create some lenders and borrowers
        _borrower  = makeAddr("borrower");
        _borrower2 = makeAddr("borrower2");
        _lender    = makeAddr("lender");
        _lender1   = makeAddr("lender1");

        // fund lenders with quote token
        deal(USDC, _lender, 120_000 * 1e18);
        deal(USDC, _lender1, 120_000 * 1e18);

        // fund borrowers with collateral
        deal(WETH, _borrower,  4 * 1e18);
        deal(WETH, _borrower2, 1_000 * 1e18);
        deal(WETH, _lender1,  4 * 1e18);

        // add liquidity to the Ajna pool
        vm.startPrank(_lender);
        usdc.approve(address(_ajnaPool), type(uint256).max);
        _ajnaPool.addQuoteToken(2_000 * 1e18, 3696);
        _ajnaPool.addQuoteToken(5_000 * 1e18, 3698);
        _ajnaPool.addQuoteToken(11_000 * 1e18, 3700);
        _ajnaPool.addQuoteToken(25_000 * 1e18, 3702);
        _ajnaPool.addQuoteToken(30_000 * 1e18, 3704);
        vm.stopPrank();

        // borrower draws debt
        vm.startPrank(_borrower);
        weth.approve(address(_ajnaPool), type(uint256).max);
        usdc.approve(address(_ajnaPool), type(uint256).max);
        _ajnaPool.pledgeCollateral(_borrower, 2 * 1e18);
        _ajnaPool.borrow(19.25 * 1e18, 3696);
        vm.stopPrank();

        // borrower2 draws debt
        vm.startPrank(_borrower2);
        weth.approve(address(_ajnaPool), type(uint256).max);
        usdc.approve(address(_ajnaPool), type(uint256).max);
        _ajnaPool.pledgeCollateral(_borrower2, 1_000 * 1e18);
        _ajnaPool.borrow(7_980 * 1e18, 3700);
        vm.stopPrank();

        // wait for borrower to become undercollateralized due to interest accrual
        skip(100 days);
        vm.prank(_lender);
        // liquidate the borrower
        _ajnaPool.kick(_borrower);
        // wait for the price to become profitable
        skip(6 hours);
    }

    function testTakeWithFlashLoan() external {
        BalancerUniswapTaker taker = new BalancerUniswapTaker();

        assertEq(0, usdc.balanceOf(address(this)));
        
        address[] memory tokens = new address[](2);
        tokens[0] = USDC;
        tokens[1] = WETH;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 * 1e6;

        bytes memory data = abi.encode(
            BalancerUniswapTaker.TakeData({
                taker:     address(this),
                ajnaPool:  address(_ajnaPool),
                borrower:  _borrower,
                maxAmount: 10 * 1e18
            })
        );
        taker.take(tokens, amounts, data);

        assertGt(usdc.balanceOf(address(this)), 1000); // could vary
    }

    function testTakeFromContractWithAtomicSwap() external {
        // instantiate a taker contract which implements IERC20Taker
        UniswapTakeExample taker = new UniswapTakeExample();
        changePrank(address(taker));
        assertEq(usdc.balanceOf(address(taker)), 0);

        // take the maximum amount of collateral from the auction
        uint256 takeAmount = type(uint256).max;
        taker.approveToken(weth);
        weth.approve(address(taker), takeAmount);
        usdc.approve(address(_ajnaPool), takeAmount);

        // call take using taker contract
        bytes memory data = abi.encode(address(_ajnaPool));
        _ajnaPool.take(_borrower, takeAmount, address(taker), data);

        // confirm we earned some quote token
        assertGt(usdc.balanceOf(address(taker)), 1000);
    }
}
