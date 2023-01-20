// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import '@std/Test.sol';
import "forge-std/console.sol";

import { ERC20Pool }        from 'src/ERC20Pool.sol';
import { ERC20PoolFactory } from 'src/ERC20PoolFactory.sol';
import { Token }            from '../../utils/Tokens.sol';
import { PoolInfoUtils }    from 'src/PoolInfoUtils.sol';
import { InvariantActorManager, LENDER_MIN_BUCKET_INDEX, LENDER_MAX_BUCKET_INDEX, BORROWER_MIN_BUCKET_INDEX} from './utils/InvariantManager.sol';

struct FuzzSelector {
    address addr;
    bytes4[] selectors;
}

// contains invariants for the test
contract PoolInvariants is Test{
    InvariantActorManager internal _invariantActorManager;

    // Mainnet ajna address
    address internal _ajna = 0x9a96ec9B57Fb64FbC60B423d1f4da7691Bd35079;
    ERC20Pool internal _pool;
    Token internal _collateral;
    Token internal _quote;
    PoolInfoUtils internal _poolInfo;
    ERC20PoolFactory internal _poolFactory;

    function setUp() public virtual {
        _collateral  = new Token("Collateral", "C");
        _quote       = new Token("Quote", "Q");
        _poolFactory = new ERC20PoolFactory(_ajna);
        _pool        = ERC20Pool(_poolFactory.deployPool(address(_collateral), address(_quote), 0.05 * 10**18));
        _poolInfo    = new PoolInfoUtils();
        _invariantActorManager = new InvariantActorManager(address(_pool), address(_quote), address(_collateral), address(_poolInfo));

        // create some actors and add liquidity
        _invariantActorManager.createActor();
        _invariantActorManager.addQuoteToken(0, 1000 * 1e18, LENDER_MIN_BUCKET_INDEX);
        _invariantActorManager.createActor();
        _invariantActorManager.addQuoteToken(1, 1000 * 1e18, LENDER_MIN_BUCKET_INDEX);
        _invariantActorManager.createActor();
        _invariantActorManager.addQuoteToken(2, 1000 * 1e18, LENDER_MIN_BUCKET_INDEX);
        _invariantActorManager.createActor();
        _invariantActorManager.addQuoteToken(3, 1000 * 1e18, LENDER_MIN_BUCKET_INDEX);

        // create some actors and borrow debt 
        _invariantActorManager.createActor();
        _invariantActorManager.drawDebt(4, 100 * 1e18, BORROWER_MIN_BUCKET_INDEX);
        _invariantActorManager.createActor();
        _invariantActorManager.drawDebt(5, 100 * 1e18, BORROWER_MIN_BUCKET_INDEX);
        _invariantActorManager.createActor();
        _invariantActorManager.drawDebt(6, 100 * 1e18, BORROWER_MIN_BUCKET_INDEX);
        _invariantActorManager.createActor();
        _invariantActorManager.drawDebt(7, 100 * 1e18, BORROWER_MIN_BUCKET_INDEX);
    }

    function targetSelectors() public returns (FuzzSelector[] memory) {
        FuzzSelector[] memory targets = new FuzzSelector[](1);
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = InvariantActorManager.drawDebt.selector;
        selectors[1] = InvariantActorManager.repayDebt.selector;
        selectors[2] = InvariantActorManager.kickAuction.selector;
        selectors[3] = InvariantActorManager.takeAuction.selector;
        targets[0] = FuzzSelector(address(_invariantActorManager), selectors);
        return targets;
    }

    // checks pool lps are equal to sum of all lender lps in a bucket 
    function invariant_Lps() public {
        uint256 actorCount = _invariantActorManager.getActorsCount();
        for(uint256 bucketIndex = LENDER_MIN_BUCKET_INDEX; bucketIndex <= LENDER_MAX_BUCKET_INDEX; bucketIndex++) {
            uint256 totalLps;
            for(uint256 i = 0; i < actorCount; i++) {
                address lender = address(_invariantActorManager.actors(i));
                (uint256 lps, ) = _pool.lenderInfo(bucketIndex, lender);
                totalLps += lps;
            }
            (uint256 poolLps, , , , ) = _pool.bucketInfo(bucketIndex);
            require(poolLps == totalLps, "Incorrect Lps");
        }
    }

    // checks pool quote token balance is greater than equals total deposits in pool
    function invariant_quoteTokenBalance() public {
        uint256 poolBalance = _quote.balanceOf(address(_pool));
        (uint256 pooldebt, , ) = _pool.debtInfo();
        // poolBalance == poolDeposit will fail due to rounding issue while converting LPs to Quote
        require(poolBalance >= _pool.depositSize() - pooldebt, "Incorrect pool Balance");
    }

    // checks pools collateral Balance to be equal to collateral pledged
    function invariant_collateralBalance() public {
        uint256 actorCount = _invariantActorManager.getActorsCount();
        uint256 totalCollateralPledged;
        for(uint256 i = 0; i < actorCount; i++) {
            address borrower = address(_invariantActorManager.actors(i));
            ( , uint256 borrowerCollateral, ) = _pool.borrowerInfo(borrower);
            totalCollateralPledged += borrowerCollateral;
        }

        require(_pool.pledgedCollateral() == totalCollateralPledged, "Incorrect Collateral Pledged");
    }

    // checks pool debt is equal to sum of all borrowers debt
    function invariant_pooldebt() public {
        uint256 actorCount = _invariantActorManager.getActorsCount();
        uint256 totalDebt;
        for(uint256 i = 0; i < actorCount; i++) {
            address borrower = address(_invariantActorManager.actors(i));
            (uint256 debt, , ) = _pool.borrowerInfo(borrower);
            totalDebt += debt;
        }

        uint256 poolDebt = _pool.totalDebt();

        require(poolDebt == totalDebt, "Incorrect pool debt");
    }

    // checks sum of all kicker bond is equal to total pool bond
    function invariant_bond() public {
        uint256 actorCount = _invariantActorManager.getActorsCount();
        uint256 totalKickerBond;
        for(uint256 i = 0; i < actorCount; i++) {
            address kicker = address(_invariantActorManager.actors(i));
            (, uint256 bond) = _pool.kickerInfo(kicker);
            totalKickerBond += bond;
        }

        uint256 totalBondInAuction;

        for(uint256 i = 0; i < actorCount; i++) {
            address borrower = address(_invariantActorManager.actors(i));
            (, , uint256 bondSize, , , , , , ) = _pool.auctionInfo(borrower);
            totalBondInAuction += bondSize;
        }

        require(totalBondInAuction == totalKickerBond, "Incorrect bond");

        (uint256 totalPoolBond, , ) = _pool.reservesInfo();

        require(totalPoolBond == totalKickerBond, "Incorrect bond");
    }
}