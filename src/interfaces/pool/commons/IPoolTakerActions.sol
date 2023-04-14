// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Taker Actions
 */
interface IPoolTakerActions {

    /**
     *  @notice Called by actors to use quote token to arb higher-priced deposit off the book.
     *  @param  borrower    Identifies the loan to liquidate.
     *  @param  depositTake If true then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  index       Index of a bucket, likely the HPB, in which collateral will be deposited.
     */
    function bucketTake(
        address borrower,
        bool    depositTake,
        uint256 index
    ) external;

    /**
     *  @notice Called by actors to purchase collateral from the auction in exchange for quote token.
     *  @param  borrower  Address of the borower take is being called upon.
     *  @param  maxAmount Max amount of collateral that will be taken from the auction (max number of NFTs in case of ERC721 pool).
     *  @param  callee    Identifies where collateral should be sent and where quote token should be obtained.
     *  @param  data      If provided, take will assume the callee implements IERC*Taker.  Take will send collateral to 
     *                    callee before passing this data to IERC*Taker.atomicSwapCallback.  If not provided, 
     *                    the callback function will not be invoked.
     */
    function take(
        address        borrower,
        uint256        maxAmount,
        address        callee,
        bytes calldata data
    ) external;

    /***********************/
    /*** Reserve Auction ***/
    /***********************/

    /**
     *  @notice Purchases claimable reserves during a CRA using Ajna token.
     *  @param  maxAmount Maximum amount of quote token to purchase at the current auction price.
     *  @return amount    Actual amount of reserves taken.
     */
    function takeReserves(
        uint256 maxAmount
    ) external returns (uint256 amount);

}