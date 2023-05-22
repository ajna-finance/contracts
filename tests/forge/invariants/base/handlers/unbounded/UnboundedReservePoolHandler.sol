// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Maths } from "src/libraries/internal/Maths.sol";

import { BaseHandler } from './BaseHandler.sol';

abstract contract UnboundedReservePoolHandler is BaseHandler {

    /*******************************/
    /*** Kicker Helper Functions ***/
    /*******************************/

    function _kickReserveAuction() internal updateLocalStateAndPoolInterest {
        numberOfCalls['UBReserveHandler.kickReserveAuction']++;

        (, uint256 claimableReserves, , , ) = _poolInfo.poolReservesInfo(address(_pool));
        if (claimableReserves == 0) return;

        // execute kick reserves only if there's enough quote tokens to reward kicker
        uint256 reward = Maths.wmul(0.01 * 1e18, claimableReserves);
        if (_quote.balanceOf(address(_pool)) < reward) return;

        try _pool.kickReserveAuction() {

            // **RE11**:  Reserves increase by claimableReserves by kickReserveAuction
            decreaseInReserves += claimableReserves;            
        } catch (bytes memory err) {
            _ensurePoolError(err);
        }
    }

    /******************************/
    /*** Taker Helper Functions ***/
    /******************************/

    function _takeReserves(
        uint256 amount_
    ) internal updateLocalStateAndPoolInterest {
        numberOfCalls['UBReserveHandler.takeReserves']++;
        
        deal(address(_ajna), _actor, type(uint256).max);
        IERC20(address(_ajna)).approve(address(_pool), type(uint256).max);

        (, uint256 claimableReservesBeforeAction, ,) = _pool.reservesInfo();

        try _pool.takeReserves(amount_) {

            (, uint256 claimableReservesAfterAction, ,) = _pool.reservesInfo();
            // reserves are guaranteed by the protocol)
            require(
                claimableReservesAfterAction < claimableReservesBeforeAction,
                "QT1: claimable reserve not avaialble to take"
            );

        } catch (bytes memory err) {
            _ensurePoolError(err);
        }
    }
}
