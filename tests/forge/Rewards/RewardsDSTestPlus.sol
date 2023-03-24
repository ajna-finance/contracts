// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import 'src/RewardsManager.sol';
import 'src/PoolInfoUtils.sol';
import 'src/PositionManager.sol';

import 'src/interfaces/rewards/IRewardsManager.sol';
import 'src/interfaces/position/IPositionManager.sol';

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import { Token }               from '../utils/Tokens.sol';
import { Strings }             from '@openzeppelin/contracts/utils/Strings.sol';

import { IPoolErrors }         from 'src/interfaces/pool/commons/IPoolErrors.sol';
import { ERC20Pool }           from 'src/ERC20Pool.sol';
import { PositionManager }     from 'src/PositionManager.sol';

import { ERC20HelperContract } from '../ERC20Pool/ERC20DSTestPlus.sol';
import { IRewardsManagerEvents } from 'src/interfaces/rewards/IRewardsManagerEvents.sol';

abstract contract RewardsDSTestPlus is IRewardsManagerEvents, ERC20HelperContract {

    address         internal _minterOne;
    address         internal _minterTwo;
    address         internal _minterThree;
    address         internal _minterFour;
    address         internal _minterFive;

    ERC20           internal _ajnaToken;

    IPool             internal _poolTwo;
    IRewardsManager   internal _rewardsManager;
    IPositionManager  internal _positionManager;

    struct MintAndMemorializeParams {
        uint256[] indexes;
        address minter;
        uint256 mintAmount;
        IPool pool;
    }

    struct TriggerReserveAuctionParams {
        address borrower;
        uint256 borrowAmount;
        uint256 limitIndex;
        IPool pool;
    }

    function _stakeToken(address pool, address owner, uint256 tokenId) internal {
        changePrank(owner);

        // approve and deposit NFT into rewards contract
        PositionManager(address(_positionManager)).approve(address(_rewardsManager), tokenId);
        vm.expectEmit(true, true, true, true);
        emit Stake(owner, address(pool), tokenId);
        _rewardsManager.stake(tokenId);

        // check token was transferred to rewards contract
        assertEq(PositionManager(address(_positionManager)).ownerOf(tokenId), address(_rewardsManager));
    }

    function _unstakeToken(
        address minter,
        address pool,
        uint256[] memory claimedArray,
        uint256 tokenId,
        uint256 reward,
        uint256 updateRatesReward
    ) internal {

        changePrank(minter);

        if (updateRatesReward != 0) {
            vm.expectEmit(true, true, true, true);
            emit UpdateExchangeRates(_minterOne, address(_pool), _positionManager.getPositionIndexes(tokenId), updateRatesReward);
        }

        vm.expectEmit(true, true, true, true);
        emit ClaimRewards(minter, pool,  tokenId, claimedArray, reward);
        vm.expectEmit(true, true, true, true);
        emit Unstake(minter, address(pool), tokenId);
        _rewardsManager.unstake(tokenId);
        assertEq(PositionManager(address(_positionManager)).ownerOf(tokenId), minter);

        // check token was transferred from rewards contract to minter
        assertEq(PositionManager(address(_positionManager)).ownerOf(tokenId), address(minter));

        // invariant: all bucket snapshots are removed for the token id that was unstaken
        for(uint256 bucketIndex = 0; bucketIndex <= 7388; bucketIndex++) {
            (uint256 lps, uint256 rate) = _rewardsManager.getBucketStateStakeInfo(tokenId, bucketIndex);
            assertEq(lps, 0);
            assertEq(rate, 0);
        }
    }

    function _assertBurn(
        address pool,
        uint256 epoch,
        uint256 timestamp,
        uint256 interest,
        uint256 burned,
        uint256 tokensToBurn,
        uint256 rewardsToClaimer,
        uint256 rewardsToUpdater
        ) internal {

        (uint256 bETimestamp, uint256 bEInterest, uint256 bEBurned) = IPool(pool).burnInfo(epoch);

        assertEq(bETimestamp, timestamp);
        assertEq(bEInterest,  interest);
        assertEq(bEBurned,    burned);
        assertEq(burned, tokensToBurn);
        assertEq(Maths.wmul(burned, 0.8 * 1e18), rewardsToClaimer);
        assertEq(Maths.wmul(burned, 0.05 * 1e18), rewardsToUpdater);
    }


    function _updateExchangeRates(
        address updater,
        address pool,
        uint256[] memory indexes,
        uint256 reward
    ) internal {
        uint256 ajnaBalPrev = _ajnaToken.balanceOf(updater);

        changePrank(updater);
        vm.expectEmit(true, true, true, true);
        emit UpdateExchangeRates(updater, pool, indexes, reward);
        _rewardsManager.updateBucketExchangeRatesAndClaim(pool, indexes);

        assertEq(_ajnaToken.balanceOf(updater), ajnaBalPrev + reward);
    }


    function _epochsClaimedArray(uint256 numberOfAuctions_, uint256 lastClaimed_) internal pure returns (uint256[] memory epochsClaimed_) {
        epochsClaimed_ = new uint256[](numberOfAuctions_);
        uint256 claimEpoch = lastClaimed_; // starting index, not inclusive

        for (uint256 i = 0; i < numberOfAuctions_; i++) {
            epochsClaimed_[i] = claimEpoch + 1;
            claimEpoch += 1;
        }
    }

    function _claimRewards(address from , uint256 tokenId, uint256 reward) internal {
        changePrank(from);
        assertEq(_ajnaToken.balanceOf(from), 0);

        uint256 currentBurnEpoch = _pool.currentBurnEpoch();
        vm.expectEmit(true, true, true, true);
        emit ClaimRewards(_minterOne, address(_pool), tokenId, _epochsClaimedArray(1, 0), reward);
        _rewardsManager.claimRewards(tokenId, currentBurnEpoch);

        assertEq(_ajnaToken.balanceOf(from), reward);
    }

    function _assertNotOwnerOfDepositRevert(address from , uint256 tokenId) internal {
        // check only deposit owner can claim rewards
        changePrank(from);
        uint256 currentBurnEpoch = _pool.currentBurnEpoch();
        vm.expectRevert(IRewardsManagerErrors.NotOwnerOfDeposit.selector);
        _rewardsManager.claimRewards(tokenId, currentBurnEpoch);
    }

    function _assertAlreadyClaimedRevert(address from , uint256 tokenId) internal {
        // check only deposit owner can claim rewards
        changePrank(from);
        uint256 currentBurnEpoch = _pool.currentBurnEpoch();
        vm.expectRevert(IRewardsManagerErrors.AlreadyClaimed.selector);
        _rewardsManager.claimRewards(tokenId, currentBurnEpoch);
    }

    function _assertExchangeRateUpdateTooLateRevert(address from , uint256[] memory indexes) internal {
        changePrank(from);
        vm.expectRevert(IRewardsManagerErrors.ExchangeRateUpdateTooLate.selector);
        uint256 updateRewards = _rewardsManager.updateBucketExchangeRatesAndClaim(address(_pool), indexes);
        assertEq(updateRewards, 0);
    }

    function _assertStake(
        address owner,
        address pool,
        uint256 tokenId,
        uint256 burnEvent,
        uint256 rewardsEarned
    ) internal {
        uint256 currentBurnEpoch = _pool.currentBurnEpoch();
        (address ownerInf, address poolInf, uint256 interactionBurnEvent) = _rewardsManager.getStakeInfo(tokenId);
        uint256 rewardsEarnedInf = _rewardsManager.calculateRewards(tokenId, currentBurnEpoch);

        assertEq(owner, ownerInf);
        assertEq(pool, poolInf);
        assertEq(burnEvent, interactionBurnEvent);
        assertEq(PositionManager(address(_positionManager)).ownerOf(tokenId), address(_rewardsManager));
    }


}




abstract contract RewardsHelperContract is RewardsDSTestPlus {

    address         internal _bidder;
    address         internal _updater;
    address         internal _updater2;

    Token internal _collateralOne;
    Token internal _quoteOne;
    Token internal _collateralTwo;
    Token internal _quoteTwo;

    constructor() {
        vm.makePersistent(_ajna);

        _ajnaToken       = ERC20(_ajna);
        _positionManager = new PositionManager(_poolFactory, new ERC721PoolFactory(_ajna));
        _rewardsManager  = new RewardsManager(_ajna, _positionManager);
        // _poolUtils       = new PoolInfoUtils();

        _collateralOne = new Token("Collateral 1", "C1");
        _quoteOne      = new Token("Quote 1", "Q1");
        _collateralTwo = new Token("Collateral 2", "C2");
        _quoteTwo      = new Token("Quote 2", "Q2");

        _poolFactory   = new ERC20PoolFactory(_ajna);
        _poolTwo       = ERC20Pool(_poolFactory.deployPool(address(_collateralTwo), address(_quoteTwo), 0.05 * 10**18));

        // provide initial ajna tokens to staking rewards contract
        deal(_ajna, address(_rewardsManager), 100_000_000 * 1e18);
        assertEq(_ajnaToken.balanceOf(address(_rewardsManager)), 100_000_000 * 1e18);

        // // instantiate test minters
        // _minterOne   = makeAddr("minterOne");
        // _minterTwo   = makeAddr("minterTwo");
        // _minterThree = makeAddr("minterThree");
        // _minterFour  = makeAddr("minterFour");
        // _minterFive  = makeAddr("minterFive");

        // // instantiate test bidder
        // _bidder    = makeAddr("bidder");
        // changePrank(_bidder);
        // deal(_ajna, _bidder, 900_000_000 * 10**18);

        // instantiate test updater
        // _updater     = makeAddr("updater");
        // _updater2    = makeAddr("updater2");
    }

    // create a new test borrower with quote and collateral sufficient to draw a specified amount of debt
    function _createTestBorrower(address pool, address borrower, uint256 borrowAmount, uint256 limitIndex) internal returns (uint256 collateralToPledge_) {

        changePrank(borrower);
        Token collateral = Token(ERC20Pool(address(pool)).collateralAddress());
        Token quote = Token(ERC20Pool(address(pool)).quoteTokenAddress());
        // deal twice as much quote so the borrower has sufficient quote to repay the loan
        deal(address(quote), borrower, Maths.wmul(borrowAmount, Maths.wad(2)));

        // approve tokens
        collateral.approve(address(pool), type(uint256).max);
        quote.approve(address(pool), type(uint256).max);

        collateralToPledge_ = _requiredCollateral(borrowAmount, limitIndex);
        deal(address(collateral), borrower, collateralToPledge_);
    }

    function _triggerReserveAuctionsNoTake(address borrower, address pool, uint256 borrowAmount, uint256 limitIndex) internal {
        // create a new borrower to write state required for reserve auctions
        uint256 collateralToPledge = _createTestBorrower(address(pool), borrower, borrowAmount, limitIndex);

        // borrower drawsDebt from the pool
        ERC20Pool(address(pool)).drawDebt(borrower, borrowAmount, limitIndex, collateralToPledge);

        // allow time to pass for interest to accumulate
        skip(26 weeks);

        // borrower repays some of their debt, providing reserves to be claimed
        // don't pull any collateral, as such functionality is unrelated to reserve auctions
        ERC20Pool(address(pool)).repayDebt(borrower, Maths.wdiv(borrowAmount, Maths.wad(2)), 0, borrower, MAX_FENWICK_INDEX);

        // start reserve auction
        changePrank(_bidder);
        
        _ajnaToken.approve(address(pool), type(uint256).max);
        ERC20Pool(address(pool)).startClaimableReserveAuction();
    }

    function _mintAndMemorializePositionNFT(address minter, uint256 mintAmount, address pool, uint256[] memory indexes) internal returns (uint256 tokenId_) {
        changePrank(minter);

        Token collateral = Token(ERC20Pool(address(pool)).collateralAddress());
        Token quote = Token(ERC20Pool(address(pool)).quoteTokenAddress());

        // deal tokens to the minter
        deal(address(collateral), minter, 250_000 * 1e18);
        deal(address(quote), minter, mintAmount * indexes.length);

        // approve tokens
        collateral.approve(address(pool), type(uint256).max);
        quote.approve(address(pool), type(uint256).max);

        IPositionManagerOwnerActions.MintParams memory mintParams = IPositionManagerOwnerActions.MintParams(minter, address(pool), keccak256("ERC20_NON_SUBSET_HASH"));
        tokenId_ = _positionManager.mint(mintParams);

        uint256[] memory lpBalances = new uint256[](indexes.length);

        for (uint256 i = 0; i < indexes.length; i++) {
            ERC20Pool(address(pool)).addQuoteToken(mintAmount, indexes[i], type(uint256).max);
            (lpBalances[i], ) = ERC20Pool(address(pool)).lenderInfo(indexes[i], minter);
        }

        ERC20Pool(address(pool)).increaseLPsAllowance(address(_positionManager), indexes, lpBalances);

        // construct memorialize params struct
        IPositionManagerOwnerActions.MemorializePositionsParams memory memorializeParams = IPositionManagerOwnerActions.MemorializePositionsParams(
            tokenId_, indexes
        );

        _positionManager.memorializePositions(memorializeParams);

        // register position manager as lender at memorialized indexes (for LP test assertions)
        _registerLender(address(_positionManager), indexes);
    }

    function _triggerReserveAuctions(
        address pool,
        address borrower,
        uint256 borrowAmount,
        uint256 limitIndex,
        uint256 tokensToBurn
    ) internal returns (uint256 tokensBurned_) {

        // fund borrower to write state required for reserve auctions
        changePrank(borrower);
        Token collateral = Token(ERC20Pool(address(pool)).collateralAddress());
        Token quote = Token(ERC20Pool(address(pool)).quoteTokenAddress());
        deal(address(quote), borrower, borrowAmount);

        // approve tokens
        collateral.approve(address(pool), type(uint256).max);
        quote.approve(address(pool), type(uint256).max);

        uint256 collateralToPledge = _requiredCollateral(borrowAmount, limitIndex);
        deal(address(_collateral), borrower, collateralToPledge);

        // borrower drawsDebt from the pool
        ERC20Pool(address(pool)).drawDebt(borrower, borrowAmount, limitIndex, collateralToPledge);

        // allow time to pass for interest to accumulate
        skip(26 weeks);

        // borrower repays some of their debt, providing reserves to be claimed
        // don't pull any collateral, as such functionality is unrelated to reserve auctions
        ERC20Pool(address(pool)).repayDebt(borrower, borrowAmount, 0, borrower, MAX_FENWICK_INDEX);

        // start reserve auction
        changePrank(_bidder);
        _ajnaToken.approve(address(pool), type(uint256).max);
        ERC20Pool(address(pool)).startClaimableReserveAuction();

        // Can't trigger reserve auction if less than two weeks have passed since last auction
        vm.expectRevert(IPoolErrors.ReserveAuctionTooSoon.selector);
        ERC20Pool(address(pool)).startClaimableReserveAuction();

        // allow time to pass for the reserve price to decrease
        skip(24 hours);

        (
            ,
            ,
            uint256 curClaimableReservesRemaining,
            ,
        ) = _poolUtils.poolReservesInfo(address(pool));

        // take claimable reserves
        ERC20Pool(address(pool)).takeReserves(curClaimableReservesRemaining);

        (,, tokensBurned_) = IPool(pool).burnInfo(IPool(pool).currentBurnEpoch());
        assertEq(tokensBurned_, tokensToBurn);

        return tokensBurned_;
    }
}
