// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


interface IAjnaRewards {

    /**************/
    /*** Errors ***/
    /**************/

    /**
     *  @notice User attempted to claim rewards multiple times.
     */
     error AlreadyClaimed();

    /**
     *  @notice User attempted to record updated exchange rates after an update already occured for the bucket.
     */
    error ExchangeRateAlreadyUpdated();

    /**
     *  @notice User attempted to record updated exchange rates outside of the allowed period.
     */
    error ExchangeRateUpdateTooLate();

    /**
     *  @notice User attempted to interact with an NFT they aren't the owner of.
     */
    error NotOwnerOfDeposit();

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @notice Emitted when lender claims rewards that have accrued to their deposit.
     *  @param  owner    Owner of the staked NFT.
     *  @param  ajnaPool Address of the Ajna pool the NFT corresponds to.
     *  @param  tokenId  ID of the staked NFT.
     *  @param  amount   The amount of AJNA tokens claimed by the depositor.
     */
    event ClaimRewards(address indexed owner, address indexed ajnaPool, uint256 indexed tokenId, uint256 amount);

    /**
     *  @notice Emitted when lender deposits their LP NFT into the rewards contract.
     *  @param  owner    Owner of the staked NFT.
     *  @param  ajnaPool Address of the Ajna pool the NFT corresponds to.
     *  @param  tokenId  ID of the staked NFT.
     */
    event DepositToken(address indexed owner, address indexed ajnaPool, uint256 indexed tokenId);

    event UpdateExchangeRates(address indexed caller, address indexed ajnaPool, uint256[] indexesUpdated, uint256 rewardsClaimed);

    /**
     *  @notice Emitted when lender withdraws their LP NFT from the rewards contract.
     *  @param  owner    Owner of the staked NFT.
     *  @param  ajnaPool Address of the Ajna pool the NFT corresponds to.
     *  @param  tokenId  ID of the staked NFT.
     */
    event WithdrawToken(address indexed owner, address indexed ajnaPool, uint256 indexed tokenId);

}
