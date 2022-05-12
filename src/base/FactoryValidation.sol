// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { console } from "@std/console.sol";

abstract contract FactoryValidation {

    bytes4 private constant ERC721 = 0x80ac58cd;
    bytes4 private constant ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant ERC721_METADATA = 0x5b5e139f;

    error WethOnly();

    /// @dev Check that native ETH isn't being used on either side of the pool
    modifier WETHOnly(address collateral_, address quote_) {
        if (collateral_ == address(0) || quote_ == address(0)) {
            revert WethOnly();
        }
        _;
    }

    // TODO: determine if this is useful -> increased gas, varying NFT signatures, vs. junk pools
    /// @notice Check if the inputted address is compliant with the ERC721 interface
    /// @dev Utilizes EIP-165
    /// @dev Retrieved from: https://stackoverflow.com/questions/45364197/how-to-detect-if-an-ethereum-address-is-an-erc20-token-contract
    function isERC721(address token_) public view returns (bool) {
        return IERC721(token_).supportsInterface(type(IERC721).interfaceId);
    }
}
