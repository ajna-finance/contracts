// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IPoolFactory } from "../base/interfaces/IPoolFactory.sol";

import { ERC20Pool } from "./ERC20Pool.sol";

import { PoolDeployer } from "../base/PoolDeployer.sol";

import { ClonesWithImmutableArgs } from "@clones/ClonesWithImmutableArgs.sol";

contract ERC20PoolFactory is IPoolFactory, PoolDeployer {

    using ClonesWithImmutableArgs for address;

    ERC20Pool public implementation;

    /// @dev Default bytes32 hash used by ERC20 Non-NFTSubset pool types
    bytes32 public constant ERC20_NON_SUBSET_HASH = keccak256("ERC20_NON_SUBSET_HASH");

    constructor() {
        implementation = new ERC20Pool();
    }

    function deployPool(
        address collateral_, address quote_, uint256 interestRate_
    ) external canDeploy(ERC20_NON_SUBSET_HASH, collateral_, quote_, interestRate_) returns (address pool_) {
        bytes memory data = abi.encodePacked(collateral_, quote_);

        ERC20Pool pool = ERC20Pool(address(implementation).clone(data));
        pool_ = address(pool);
        deployedPools[ERC20_NON_SUBSET_HASH][collateral_][quote_] = pool_;
        emit PoolCreated(pool_);

        pool.initialize(interestRate_, ajnaTokenAddress);
    }
}
