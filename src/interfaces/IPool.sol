// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Ajna Pool
interface IPool {

    struct BorrowerInfo {
        uint256 debt; // WAD
        uint256 collateralDeposited; // WAD
        uint256 inflatorSnapshot; // RAY, the inflator rate of the given borrower's last state change
    }

    event AddQuoteToken(address indexed lender, uint256 indexed price, uint256 amount, uint256 lup);
    event RemoveQuoteToken(
        address indexed lender,
        uint256 indexed price,
        uint256 amount,
        uint256 lup
    );
    event AddCollateral(address indexed borrower, uint256 amount);
    event RemoveCollateral(address indexed borrower, uint256 amount);
    event ClaimCollateral(
        address indexed claimer,
        uint256 indexed price,
        uint256 amount,
        uint256 lps
    );
    event Borrow(address indexed borrower, uint256 lup, uint256 amount);
    event Repay(address indexed borrower, uint256 lup, uint256 amount);
    event UpdateInterestRate(uint256 oldRate, uint256 newRate);
    event Purchase(
        address indexed bidder,
        uint256 indexed price,
        uint256 amount,
        uint256 collateral
    );
    event Liquidate(address indexed borrower, uint256 debt, uint256 collateral);

    error AlreadyInitialized();
    error InvalidPrice();
    error NoClaimToBucket();
    error NoDebtToRepay();
    error NoDebtToLiquidate();
    error InsufficientBalanceForRepay();
    error InsufficientCollateralBalance();
    error InsufficientCollateralForBorrow();
    error InsufficientLiquidity(uint256 amountAvailable);
    error PoolUndercollateralized(uint256 collateralization);
    error BorrowerIsCollateralized(uint256 collateralization);
    error AmountExceedsTotalClaimableQuoteToken(uint256 totalClaimable);
    error AmountExceedsAvailableCollateral(uint256 availableCollateral);

    /// @notice Called by lenders to add an amount of credit at a specified price bucket
    /// @param recipient_ The recipient adding quote tokens
    /// @param amount_ The amount of quote token to be added by a lender
    /// @param price_ The bucket to which the quote tokens will be added
    /// @return lpTokens_ The amount of LP Tokens received for the added quote tokens
    function addQuoteToken(address recipient_, uint256 amount_, uint256 price_) external returns (uint256 lpTokens_);

    /// @notice Called by lenders to remove an amount of credit at a specified price bucket
    /// @param recipient_ The recipient removing quote tokens
    /// @param maxAmount_ The maximum amount of quote token to be removed by a lender
    /// @param price_ The bucket from which quote tokens will be removed
    function removeQuoteToken(address recipient_, uint256 maxAmount_, uint256 price_) external;

    /// @notice Called by borrowers to add collateral to the pool
    /// @param amount_ The amount of collateral in deposit tokens to be added to the pool
    function addCollateral(uint256 amount_) external;

    function removeCollateral(uint256 amount_) external;

    function claimCollateral(address recipient_, uint256 amount_, uint256 price_) external;

    function borrow(uint256 amount_, uint256 stopPrice_) external;

    function repay(uint256 amount_) external;

    function purchaseBid(uint256 amount_, uint256 price_) external;

    function getLPTokenBalance(address owner_, uint256 price_) external view returns (uint256 lpTokens_);

    function getLPTokenExchangeValue(uint256 lpTokens_, uint256 price_) external view returns (uint256 collateralTokens_, uint256 quoteTokens_);

    function liquidate(address borrower_) external;

}
