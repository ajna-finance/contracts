// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import { ERC20 }             from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ERC721Pool }        from "../../erc721/ERC721Pool.sol";
import { ERC721PoolFactory } from "../../erc721/ERC721PoolFactory.sol";
import { IScaledPool}        from "../../base/interfaces/IScaledPool.sol";

import { DSTestPlus }                from "../utils/DSTestPlus.sol";
import { NFTCollateralToken, Token } from "../utils/Tokens.sol";

abstract contract ERC721DSTestPlus is DSTestPlus {

    // ERC721 events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Pool events
    event AddCollateralNFT(address indexed actor_, uint256 indexed price_, uint256[] tokenIds_);
    event PledgeCollateralNFT(address indexed borrower_, uint256[] tokenIds_);
    event PurchaseWithNFTs(address indexed bidder_, uint256 indexed price_, uint256 amount_, uint256[] tokenIds_);
    event PullCollateralNFT(address indexed borrower_, uint256[] tokenIds_);
    event RemoveCollateralNFT(address indexed claimer_, uint256 indexed price_, uint256[] tokenIds_);
    event Repay(address indexed borrower_, uint256 lup_, uint256 amount_);
    event ReserveAuction(uint256 claimableReservesRemaining_, uint256 auctionPrice_);

    /*****************/
    /*** Utilities ***/
    /*****************/

    

    struct ReserveAuctionState {
        uint256 claimableReservesRemaining;
        uint256 auctionPrice;
        uint256 timeRemaining;
    }
}

abstract contract ERC721HelperContract is ERC721DSTestPlus {

    uint256 public constant LARGEST_AMOUNT = type(uint256).max / 10**27;

    NFTCollateralToken internal _collateral;
    Token              internal _quote;
    ERC20              internal _ajna;
    ERC721Pool         internal _pool;

    // TODO: bool for pool type
    constructor() {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        _collateral = new NFTCollateralToken();
        vm.makePersistent(address(_collateral));
        _quote      = new Token("Quote", "Q");
        vm.makePersistent(address(_quote));
        _ajna       = ERC20(address(0x9a96ec9B57Fb64FbC60B423d1f4da7691Bd35079));
        vm.makePersistent(address(_ajna));
    }

    function _deployCollectionPool() internal returns (ERC721Pool) {
        address contractAddress = new ERC721PoolFactory().deployPool(address(_collateral), address(_quote), 0.05 * 10**18);
        vm.makePersistent(contractAddress);
        return ERC721Pool(contractAddress);
    }

    function _deploySubsetPool(uint256[] memory subsetTokenIds_) internal returns (ERC721Pool) {
        return ERC721Pool(new ERC721PoolFactory().deploySubsetPool(address(_collateral), address(_quote), subsetTokenIds_, 0.05 * 10**18));
    }

    // TODO: finish implementing
    function _approveQuoteMultipleUserMultiplePool() internal {

    }

    function _mintAndApproveQuoteTokens(address operator_, uint256 mintAmount_) internal {
        deal(address(_quote), operator_, mintAmount_);
        vm.prank(operator_);
        _quote.approve(address(_pool), type(uint256).max);
    }

    function _mintAndApproveCollateralTokens(address operator_, uint256 mintAmount_) internal {
        _collateral.mint(operator_, mintAmount_);
        vm.prank(operator_);
        _collateral.setApprovalForAll(address(_pool), true);
    }

    function _mintAndApproveAjnaTokens(address operator_, uint256 mintAmount_) internal {
        deal(address(_ajna), operator_, mintAmount_);
        vm.prank(operator_);
        _ajna.approve(address(_pool), type(uint256).max);
    }

    // TODO: implement this
    function _assertBalances() internal {}

    // TODO: check oldPrev and newPrev
    function _pledgeCollateral(address pledger_, address borrower_, ERC721Pool pool_, uint256[] memory tokenIdsToAdd_) internal {
        vm.prank(pledger_);
        for (uint i; i < tokenIdsToAdd_.length;) {
            emit Transfer(address(borrower_), address(pool_), tokenIdsToAdd_[i]);
            vm.expectEmit(true, true, false, true);
            unchecked {
                ++i;
            }
        }
        emit PledgeCollateralNFT(address(borrower_), tokenIdsToAdd_);
        pool_.pledgeCollateral(borrower_, tokenIdsToAdd_);
    }

    // TODO: implement _pullCollateral()
    
    function _assertPool(PoolState memory state_) internal {
        ( , uint256 htp, uint256 lup, ) = _pool.poolPricesInfo();
        (uint256 poolSize, uint256 loansCount, address maxBorrower, ) = _pool.poolLoansInfo();
        (uint256 poolMinDebtAmount, , uint256 poolActualUtilization, uint256 poolTargetUtilization) = _pool.poolUtilizationInfo();
        assertEq(htp, state_.htp);
        assertEq(lup, state_.lup);

        assertEq(poolSize,                  state_.poolSize);
        assertEq(_pool.pledgedCollateral(), state_.pledgedCollateral);
        assertEq(_pool.borrowerDebt(),      state_.borrowerDebt);
        assertEq(poolActualUtilization,     state_.actualUtilization);
        assertEq(poolTargetUtilization,     state_.targetUtilization);
        assertEq(poolMinDebtAmount,         state_.minDebtAmount);

        assertEq(loansCount,  state_.loans);
        assertEq(maxBorrower, state_.maxBorrower);

        assertEq(_pool.encumberedCollateral(state_.borrowerDebt, state_.lup), state_.encumberedCollateral);
    }

    function _assertAuction(AuctionState memory state_) internal {
        ERC721Pool pool = address(_collectionPool) == address(0) ? _subsetPool : _collectionPool;

        (uint256 debt, , uint256 col, uint256 mompFactor, uint256 inflator) = pool.borrowerInfo(state_.borrower);
        (uint128 kickTime, uint256 referencePrice, uint256 bondFactor, uint256 bondSize) = pool.liquidations(state_.borrower);
        (address next, , bool active) = pool.getAuction(state_.borrower);
        int256 bpf = pool.bpf(
            IScaledPool.Borrower({
               debt: debt,
               collateral: col,
               mompFactor: mompFactor,
               inflatorSnapshot: inflator
            }),
            IScaledPool.Liquidation({
                kickTime: kickTime,
                referencePrice: referencePrice,
                bondFactor: bondFactor,
                bondSize: bondSize
            }),
            pool.auctionPrice(referencePrice, kickTime)
        );
        assertEq(kickTime, state_.kickTime);
        assertEq(referencePrice, state_.referencePrice);
        assertEq(pool.auctionPrice(referencePrice, kickTime), state_.price);
        assertEq(bpf, state_.bpf);
        assertEq(bondFactor, state_.bondFactor);
        assertEq(bondSize, state_.bondSize);
        assertEq(next, state_.next);
        assertEq(active, state_.active);
        
    }

    function _assertBorrower(BorrowerState memory state_) internal {
        ERC721Pool pool = address(_collectionPool) == address(0) ? _subsetPool : _collectionPool;

        (uint256 debt, uint256 pendingDebt, uint256 col, uint256 mompFactor, uint256 inflator) = pool.borrowerInfo(state_.borrower);
        (, , uint256 lup, ) = pool.poolPricesInfo();
        assertEq(debt,        state_.debt);
        assertEq(pendingDebt, state_.pendingDebt);
        assertEq(col,         state_.collateral);
        assertEq(mompFactor,  state_.mompFactor);
        assertEq(inflator,    state_.inflator);

        assertEq(pool.borrowerCollateralization(state_.debt, state_.collateral, lup), state_.collateralization);
    }

    function _assertReserveAuction(ReserveAuctionState memory state_) internal {
        ( , , uint256 claimableReservesRemaining, uint256 auctionPrice, uint256 timeRemaining) = _pool.poolReservesInfo();
        assertEq(claimableReservesRemaining, state_.claimableReservesRemaining);
        assertEq(auctionPrice, state_.auctionPrice);
        assertEq(timeRemaining, state_.timeRemaining);
    }

    function _assertReserveAuctionPrice(uint256 expectedPrice) internal {
        ( , , , uint256 auctionPrice, ) = _pool.poolReservesInfo();
        assertEq(auctionPrice, expectedPrice);
    }

    function _indexToPrice(uint256 index_) internal view returns (uint256 price_) {
        ( price_, , , , , , ) = _pool.bucketAt(index_);
    }

    function _htp() internal view returns (uint256 htp_) {
        (, htp_, , ) = _pool.poolPricesInfo();
    }

    function _exchangeRate(uint256 index_) internal view returns (uint256 exchangeRate_) {
        ( , , , , , exchangeRate_, ) = _pool.bucketAt(index_);
    }

    function _lup() internal view returns (uint256 lup_) {
        (, , lup_, ) = _pool.poolPricesInfo();
    }

    function _poolSize() internal view returns (uint256 poolSize_) {
        (poolSize_, , , ) = _pool.poolLoansInfo();
    }

    function _poolTargetUtilization() internal view returns (uint256 utilization_) {
        ( , , , utilization_) = _pool.poolUtilizationInfo();
    }

    function _poolActualUtilization() internal view returns (uint256 utilization_) {
        ( , , utilization_, ) = _pool.poolUtilizationInfo();
    }

    function _poolMinDebtAmount() internal view returns (uint256 minDebt_) {
        ( minDebt_, , , ) = _pool.poolUtilizationInfo();
    }

    function _loansCount() internal view returns (uint256 loansCount_) {
        ( , loansCount_, , ) = _pool.poolLoansInfo();
    }

    function _maxBorrower() internal view returns (address maxBorrower_) {
        ( , , maxBorrower_, ) = _pool.poolLoansInfo();
    }
}
