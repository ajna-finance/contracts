// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IPool }                     from 'src/base/interfaces/IPool.sol';
import { IERC20PoolBorrowerActions } from 'src/erc20/interfaces/pool/IERC20PoolBorrowerActions.sol';
import { IERC20PoolLenderActions }   from 'src/erc20/interfaces/pool/IERC20PoolLenderActions.sol';
import { IERC20PoolImmutables }      from 'src/erc20/interfaces/pool/IERC20PoolImmutables.sol';
import { IERC20PoolEvents }          from 'src/erc20/interfaces/pool/IERC20PoolEvents.sol';

/**
 * @title ERC20 Pool
 */
interface IERC20Pool is
    IPool,
    IERC20PoolLenderActions,
    IERC20PoolBorrowerActions,
    IERC20PoolImmutables,
    IERC20PoolEvents
{

    /**
     *  @notice Initializes a new pool, setting initial state variables.
     *  @param  rate Initial interest rate of the pool.
     */
    function initialize(uint256 rate) external;

}
