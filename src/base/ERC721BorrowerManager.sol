// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { BaseBorrowerManager } from "./BaseBorrowerManager.sol";
import { ERC721Interest }      from "./ERC721Interest.sol";

import { INFTBorrowerManager } from "../interfaces/IBorrowerManager.sol";

import { BucketMath } from "../libraries/BucketMath.sol";
import { Maths }      from "../libraries/Maths.sol";

/**
 *  @notice Lender Management related functionality
 */
abstract contract ERC721BorrowerManager is INFTBorrowerManager, BaseBorrowerManager, ERC721Interest {

    using EnumerableSet for EnumerableSet.UintSet;

    // TODO: rename
    /// @dev Internal visibility is required as it contains a nested struct
    // borrowers book: borrower address -> NFTBorrowerInfo
    mapping(address => NFTBorrowerInfo) internal NFTborrowers;

    /**********************/
    /*** View Functions ***/
    /**********************/

    function getBorrowerInfo(address borrower_)
        public view returns (
            uint256 debt_,
            uint256 pendingDebt_,
            uint256[] memory collateralDeposited_,
            uint256 collateralEncumbered_,
            uint256 collateralization_,
            uint256 borrowerInflatorSnapshot_,
            uint256 inflatorSnapshot_
        )
    {
        NFTBorrowerInfo storage borrower = NFTborrowers[borrower_];

        debt_                     = borrower.debt;
        pendingDebt_              = debt_;
        collateralDeposited_      = borrower.collateralDeposited.values();
        collateralization_        = Maths.WAD;
        borrowerInflatorSnapshot_ = borrower.inflatorSnapshot;
        inflatorSnapshot_         = inflatorSnapshot;

        if (debt_ > 0 && borrowerInflatorSnapshot_ != 0) {
            pendingDebt_          += _pendingInterest(debt_, getPendingInflator(), borrowerInflatorSnapshot_);
            collateralEncumbered_ = getEncumberedCollateral(pendingDebt_);
            collateralization_    = Maths.wrdivw(Maths.wad(borrower.collateralDeposited.length()), collateralEncumbered_);
        }
    }

}
