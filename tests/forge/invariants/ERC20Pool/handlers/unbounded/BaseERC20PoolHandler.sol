// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

import { ERC20Pool }        from 'src/ERC20Pool.sol';

import { TokenWithNDecimals } from '../../../../utils/Tokens.sol';

import { BaseHandler } from '../../../base/handlers/unbounded/BaseHandler.sol';

abstract contract BaseERC20PoolHandler is BaseHandler {

    // Token
    TokenWithNDecimals internal _collateral;

    // ERC20Pool
    ERC20Pool     internal _erc20Pool;

    constructor(
        address pool_,
        address ajna_,
        address quote_,
        address collateral_,
        address poolInfo_,
        uint256 numOfActors_,
        address testContract_
    ) BaseHandler(pool_, ajna_, quote_, poolInfo_, testContract_) {

        LENDER_MIN_BUCKET_INDEX = 2570;
        LENDER_MAX_BUCKET_INDEX = 2572;

        // Tokens
        _collateral = TokenWithNDecimals(collateral_);

        // Pool
        _erc20Pool  = ERC20Pool(pool_);

        // Actors
        actors = _buildActors(numOfActors_);
    }

    /*****************************/
    /*** Pool Helper Functions ***/
    /*****************************/

    function _buildActors(uint256 noOfActors_) internal returns(address[] memory) {
        address[] memory actorsAddress = new address[](noOfActors_);

        for (uint i = 0; i < noOfActors_; i++) {
            address actor = makeAddr(string(abi.encodePacked("Actor", Strings.toString(i))));
            actorsAddress[i] = actor;

            vm.startPrank(actor);

            _quote.mint(actor, 1e45);
            _quote.approve(address(_pool), 1e45);

            _collateral.mint(actor, 1e45);
            _collateral.approve(address(_pool), 1e45);

            vm.stopPrank();
        }

        return actorsAddress;
    }

}