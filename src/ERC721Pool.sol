// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { Clone } from "@clones/Clone.sol";

import { console }     from "@std/console.sol";

import { ERC20 }         from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 }     from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 }        from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { BitMaps }       from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { BorrowerManager } from "./base/BorrowerManager.sol";
import { LenderManager }   from "./base/LenderManager.sol";

import { IPool } from "./interfaces/IPool.sol";

import { BucketMath } from "./libraries/BucketMath.sol";
import { Maths }      from "./libraries/Maths.sol";


contract ERC721Pool is IPool, BorrowerManager, Clone, LenderManager {

    using SafeERC20 for ERC20;

    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev Counter used by onlyOnce modifier
    uint8 private _poolInitializations = 0;

    /// @dev Set of tokenIds that are currently being used as collateral
    EnumerableSet.UintSet internal _collateralTokenIdsAdded;
    /// @dev Set of tokenIds that can be used for a given NFT Subset type pool
    EnumerableSet.UintSet internal _tokenIdsAllowed;

    uint256 public override quoteTokenScale;

    /// @notice Modifier to protect a clone's initialize method from repeated updates
    modifier onlyOnce() {
        require(_poolInitializations == 0, "P:INITIALIZED");
        _;
    }

    // TODO: convert to modifier and add check at start of each method
    function onlySubset(uint256 tokenId_) internal view {
        if (_tokenIdsAllowed.length() != 0) {

            bool isAllowed = _tokenIdsAllowed.contains(tokenId_);

            if (isAllowed == false) {
                revert("P:ONLY_SUBSET");
            }
        }
    }

    function initialize() external onlyOnce {
        quoteTokenScale = 10**(18 - quoteToken().decimals());

        inflatorSnapshot           = Maths.ONE_RAY;
        lastInflatorSnapshotUpdate = block.timestamp;
        previousRate               = Maths.wdiv(5, 100);
        previousRateUpdate         = block.timestamp;

        // increment initializations count to ensure these values can't be updated
        _poolInitializations += 1;
    }

    /**
     * @notice Called by deployNFTSubsetPool()
     * @dev Used to initialize pools that only support a subset of tokenIds
     */
    function initializeSubset(uint256[] memory tokenIds_) external onlyOnce {
        quoteTokenScale = 10**(18 - quoteToken().decimals());

        inflatorSnapshot           = Maths.ONE_RAY;
        lastInflatorSnapshotUpdate = block.timestamp;
        previousRate               = Maths.wdiv(5, 100);
        previousRateUpdate         = block.timestamp;

        // increment initializations count to ensure these values can't be updated
        _poolInitializations += 1;

        // add subset of tokenIds allowed in the pool
        for (uint256 id; id < tokenIds_.length;) {
            _tokenIdsAllowed.add(tokenIds_[id]);
            unchecked {
                ++id;
            }
        }
    }

    /// @dev Quote tokens are always non-fungible
    /// @dev Pure function used to facilitate accessing token via clone state
    function collateral() public pure returns (ERC721) {
        return ERC721(_getArgAddress(0));
    }

    /// @dev Quote tokens are always fungible
    /// @dev Pure function used to facilitate accessing token via clone state
    function quoteToken() public pure returns (ERC20) {
        return ERC20(_getArgAddress(0x14));
    }

    function addQuoteToken(
        address recipient_, uint256 amount_, uint256 price_
    ) external override returns (uint256 lpTokens_) {
        require(BucketMath.isValidPrice(price_), "P:AQT:INVALID_PRICE");

        accumulatePoolInterest();

        // deposit quote token amount and get awarded LP tokens
        lpTokens_ = addQuoteTokenToBucket(price_, amount_, totalDebt, inflatorSnapshot);

        // pool level accounting
        totalQuoteToken               += amount_;

        // lender accounting
        lpBalance[recipient_][price_] += lpTokens_;

        // move quote token amount from lender to pool
        quoteToken().safeTransferFrom(recipient_, address(this), amount_ / quoteTokenScale);
        emit AddQuoteToken(recipient_, price_, amount_, lup);
    }

    function removeQuoteToken(address recipient_, uint256 maxAmount_, uint256 price_) external override {
        require(BucketMath.isValidPrice(price_), "P:RQT:INVALID_PRICE");

        accumulatePoolInterest();

        // remove quote token amount and get LP tokens burned
        (uint256 amount, uint256 lpTokens) = removeQuoteTokenFromBucket(
            price_, maxAmount_, lpBalance[recipient_][price_], inflatorSnapshot
        );

        // pool level accounting
        totalQuoteToken -= amount;

        require(getPoolCollateralization() >= Maths.ONE_WAD, "P:RQT:POOL_UNDER_COLLAT");

        // lender accounting
        lpBalance[recipient_][price_] -= lpTokens;

        // move quote token amount from pool to lender
        quoteToken().safeTransfer(recipient_, amount / quoteTokenScale);
        emit RemoveQuoteToken(recipient_, price_, amount, lup);
    }

    function moveQuoteToken(
        address recipient_, uint256 amount_, uint256 fromPrice_, uint256 toPrice_
    ) external override {
        require(BucketMath.isValidPrice(toPrice_), "P:MQT:INVALID_TO_PRICE");
        require(fromPrice_ != toPrice_, "P:MQT:SAME_PRICE");

        accumulatePoolInterest();

        (uint256 fromLpTokens, uint256 toLpTokens) = moveQuoteTokenFromBucket(
            fromPrice_, toPrice_, amount_, lpBalance[recipient_][fromPrice_], inflatorSnapshot
        );

        require(getPoolCollateralization() >= Maths.ONE_WAD, "P:MQT:POOL_UNDER_COLLAT");

        // lender accounting
        lpBalance[recipient_][fromPrice_] -= fromLpTokens;
        lpBalance[recipient_][toPrice_]   += toLpTokens;

        emit MoveQuoteToken(recipient_, fromPrice_, toPrice_, amount_, lup);
    }

    // TODO: create seperate NFT specific events
    function addCollateral(uint256 tokenId_) external  override {
        // check if collateral is valid
        onlySubset(tokenId_);

        accumulatePoolInterest();

        // pool level accounting
        _collateralTokenIdsAdded.add(tokenId_);
        totalCollateral = _collateralTokenIdsAdded.length();

        // borrower accounting
        NFTborrowers[msg.sender].collateralDeposited.add(tokenId_);

        // TODO: verify that the pool address is the holder of any token balances - i.e. if any funds are held in an escrow for backup interest purposes
        // move collateral from sender to pool
        collateral().safeTransferFrom(msg.sender, address(this), tokenId_);
        emit AddCollateral(msg.sender, tokenId_);
    }

    // TODO: finish implementing
    // TODO: move check to onlySubsetMultiple()
    // TODO: update to incrementally add if contains, otherwise skip?
    // TODO: integrate multicall here
    function addCollateralMultiple(uint256[] memory tokenIds_) external {
        // check if all incoming tokenIds are part of the pool subset
        for (uint i; i < tokenIds_.length;) {
            onlySubset(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }

        // add tokenIds to the pool
        // for (uint i; i < tokenIds_.length;) {
        //     addCollateral(tokenIds_[i]);
        //     unchecked {
        //         ++i;
        //     }
        // }
    }

    function removeCollateral(uint256 tokenId_) external {
        accumulatePoolInterest();

        NFTBorrowerInfo storage borrower = NFTborrowers[msg.sender];
        accumulateNFTBorrowerInterest(borrower);

        uint256 encumberedBorrowerCollateral = getEncumberedCollateral(borrower.debt);

        // Require overcollateralization to be at a minimum of one WAD to account for indivisible NFTs
        require(Maths.ray(borrower.collateralDeposited.length()) - encumberedBorrowerCollateral >= Maths.ONE_RAY, "P:RC:AMT_GT_AVAIL_COLLAT");

        // pool level accounting
        _collateralTokenIdsAdded.remove(tokenId_);
        totalCollateral = _collateralTokenIdsAdded.length();

        // borrower accounting
        borrower.collateralDeposited.remove(tokenId_);

        // move collateral from pool to sender
        collateral().safeTransferFrom(address(this), msg.sender, tokenId_);
        emit RemoveCollateral(msg.sender, tokenId_);
    }

    // TODO: update this to remove one NFT vs a given tokenId...? findTokenId to claim
    // TODO: update to NFT specific claim event
    function claimCollateral(address recipient_, uint256 tokenId_, uint256 price_) external {
        require(BucketMath.isValidPrice(price_), "P:CC:INVALID_PRICE");

        uint256 maxClaim = lpBalance[recipient_][price_];
        require(maxClaim != 0, "P:CC:NO_CLAIM_TO_BUCKET");

        // claim collateral and get amount of LP tokens burned for claim
        uint256 claimedLpTokens = claimNFTCollateralFromBucket(price_, tokenId_, maxClaim);

        // lender accounting
        lpBalance[recipient_][price_] -= claimedLpTokens;

        // move claimed collateral from pool to claimer
        collateral().safeTransferFrom(address(this), recipient_, tokenId_);
        emit ClaimCollateral(recipient_, price_, tokenId_, claimedLpTokens);
    }

    function claimCollateralMultiple(address recipient_, uint256[] memory tokenIds_, uint256 price_) external {

    }

    function borrow(uint256 amount_, uint256 limitPrice_) external {
        require(amount_ <= totalQuoteToken, "P:B:INSUF_LIQ");

        accumulatePoolInterest();

        NFTBorrowerInfo storage borrower = NFTborrowers[msg.sender];
        accumulateNFTBorrowerInterest(borrower);

        // borrow amount from buckets with limit price
        borrowFromBucket(amount_, limitPrice_, inflatorSnapshot);

        // collateral amounts need to be recorded as WADs to enable like-unit comparisons with quote token precision
        require(Maths.ray(borrower.collateralDeposited.length()) > getEncumberedCollateral(borrower.debt + amount_), "P:B:INSUF_COLLAT");

        // pool level accounting
        totalQuoteToken -= amount_;
        totalDebt       += amount_;

        // borrower accounting
        borrower.debt   += amount_;

        // TODO: check this condition -> should collateral be stored as a WAD...?
        require(getNFTPoolCollateralization() >= Maths.ONE_WAD, "P:B:POOL_UNDER_COLLAT");

        // move borrowed amount from pool to sender
        quoteToken().safeTransfer(msg.sender, amount_ / quoteTokenScale);
        emit Borrow(msg.sender, lup, amount_);
    }

    function repay(uint256 amount_) external {}

    // TODO: Remove from IPool ... different Interface req
    function purchaseBid(uint256 amount_, uint256 price_) external {}

    // TODO: finish implementing
    /// @dev Can be called for multiple unit of collateral at a time
    function purchaseBidNFTCollateral(uint256 amount_, uint256 price_, uint256[] memory tokenIds_) external {
        require(BucketMath.isValidPrice(price_), "P:PB:INVALID_PRICE");

        // check if incoming tokens are part of the pool subset
        for (uint i; i < tokenIds_.length;) {
            onlySubset(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }

        // convert amount from WAD to pool precision - RAD
        uint256 collateralRequired = Maths.divRoundingUp(amount_, price_);
        require(collateral().balanceOf(msg.sender) >= collateralRequired, "P:PB:INSUF_COLLAT");

        accumulatePoolInterest();

        purchaseBidFromBucket(price_, amount_, collateralRequired, inflatorSnapshot);

        // pool level accounting
        totalQuoteToken -= amount_;

        require(getNFTPoolCollateralization() >= Maths.ONE_WAD, "P:PB:POOL_UNDER_COLLAT");

        // move required collateral from sender to pool
        for (uint i; i < tokenIds_.length;) {
            collateral().safeTransferFrom(msg.sender, address(this), tokenIds_[i]);
            unchecked {
                ++i;
            }
        }

        // move quote token amount from pool to sender
        quoteToken().safeTransfer(msg.sender, amount_ / quoteTokenScale);
        emit Purchase(msg.sender, price_, amount_, Maths.wad(collateralRequired));
    }

    function liquidate(address borrower_) external {}

    // Implementing this method allows contracts to receive ERC721 tokens
    // https://forum.openzeppelin.com/t/erc721holder-ierc721receiver-and-onerc721received/11828
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

   /*****************************/
    /*** Pool State Management ***/
    /*****************************/

    // WARNING: This is an extremely gas intensive operation and should only be done in view accessors
    function getCollateralDeposited() public view returns(uint256[] memory) {
        return _collateralTokenIdsAdded.values();
    }

    // WARNING: This is an extremely gas intensive operation and should only be done in view accessors
    function getTokenIdsAllowed() public view returns(uint256[] memory) {
        return _tokenIdsAllowed.values();
    }

}
