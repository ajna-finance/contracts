// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPerpPool {
    function depositCollateral(uint256 _amount) external;
    function withdrawCollateral(uint256 _amount) external;
    function depositQuoteToken(uint256 _amount, uint256 _price) external;
    function withdrawQuoteToken(uint256 _amount) external;
    function borrow(uint256 _amount) external;
    function actualUtilization() external view returns (uint256);
    function targetUtilization() external view returns (uint256);
}

contract ERC20PerpPool is IPerpPool {

    struct PriceBucket {
        mapping(address => uint256) lpTokenBalance;
        uint256 onDeposit;
        uint256 totalDebitors;
        mapping(uint256 => address) indexToDebitor;
        mapping(address => uint256) debitorToIndex;
        mapping(address => uint256) debt;
        uint256 debtAccumulator;
        uint256 price;
    }

    struct BorrowerInfo {
        // address borrower;
        uint256 collateralEncumbered;
        uint256 debt;
        uint256 inflatorSnapshot;
    }

    // --- Math ---
    uint private constant WAD = 10 ** 18;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        z = x >= y ? x : y;
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x <= y ? x : y;
    }

    event CollateralDeposited(address depositor, uint256 amount, uint256 collateralAccumulator);
    event CollateralWithdrawn(address depositor, uint256 amount, uint256 collateralAccumulator);

    uint public constant HIGHEST_UTILIZABLE_PRICE = 1;
    uint public constant LOWEST_UTILIZED_PRICE = 2;

    uint public constant SECONDS_PER_YEAR = 3600 * 24 * 365;
    uint public constant MAX_PRICE = 1000 * WAD;
    uint public constant MIN_PRICE = 10 * WAD;
    uint public constant PRICE_COUNT = 10;
    uint public constant PRICE_STEP = (MAX_PRICE - MIN_PRICE) / PRICE_COUNT;

    IERC20 public immutable collateralToken;
    mapping(address => uint256) public collateralBalances;
    uint256 public collateralAccumulator;

    IERC20 public immutable quoteToken;
    mapping(address => uint256) public quoteBalances;
    uint256 public quoteTokenAccumulator;

    mapping(uint256 => uint256) public priceToIndex;
    mapping(uint256 => uint256) public indexToPrice;
    mapping(uint256 => uint256) public pointerToIndex;

    mapping(uint256 => PriceBucket) public buckets;

    mapping(address => BorrowerInfo) public borrowers;

    uint256 public borrowerInflator;
    uint256 public lastBorrowerInflatorUpdate;
    uint256 public previousRate;
    uint256 public previousRateUpdate;

    constructor(IERC20 _collateralToken, IERC20 _quoteToken) {

        collateralToken = _collateralToken;
        quoteToken = _quoteToken;

        borrowerInflator = 1 * WAD;
        lastBorrowerInflatorUpdate = block.timestamp;

        previousRate = wdiv(5, 100);
        previousRateUpdate = block.timestamp;

        for (uint256 i = 0; i < PRICE_COUNT; i++) {
            uint256 price = MIN_PRICE + (PRICE_STEP * i);
            priceToIndex[price] = i;
            indexToPrice[i] = price;

            buckets[i].price = price;
        }
    }

    modifier updateBorrowerInflator(address account) {
        _;
        uint256 secondsSinceLastUpdate = block.timestamp - lastBorrowerInflatorUpdate;
        if (secondsSinceLastUpdate == 0) {
            return;
        }

        borrowerInflator = borrowerInflatorPending();
        lastBorrowerInflatorUpdate = block.timestamp;
    }

    function depositCollateral(uint256 _amount) external updateBorrowerInflator(msg.sender) {
        collateralBalances[msg.sender] += _amount;
        collateralAccumulator += _amount;

        collateralToken.transferFrom(msg.sender, address(this), _amount);
        emit CollateralDeposited(msg.sender, _amount, collateralAccumulator);
    }

    function withdrawCollateral(uint256 _amount) external updateBorrowerInflator(msg.sender) {
        require(_amount <= collateralBalances[msg.sender], "Not enough collateral to withdraw");

        collateralBalances[msg.sender] -= _amount;
        collateralAccumulator -= _amount;

        collateralToken.transferFrom(address(this), msg.sender, _amount);
        emit CollateralWithdrawn(msg.sender, _amount, collateralAccumulator);
    }

    function depositQuoteToken(uint256 _amount, uint256 _price) external {

        uint256 depositIndex = priceToIndex[_price];
        require(depositIndex > 0, "Price bucket not found");

        PriceBucket storage toBucket = buckets[depositIndex];
        toBucket.lpTokenBalance[msg.sender] += _amount;
        toBucket.onDeposit += _amount;

        quoteBalances[msg.sender] += _amount;
        quoteTokenAccumulator += _amount;

        uint256 lupIndex = pointerToIndex[LOWEST_UTILIZED_PRICE];
        if (depositIndex > lupIndex) {
            for (uint256 i = lupIndex; i < depositIndex; i++) {

                PriceBucket storage fromBucket = buckets[i];
                require(fromBucket.price < toBucket.price, "To bucket price not greater than from bucket price");

                for (uint256 debitorIndex = 0; debitorIndex < fromBucket.totalDebitors; debitorIndex++) {
                    address debitor = fromBucket.indexToDebitor[debitorIndex];
                    uint256 debtToReallocate = min(fromBucket.debt[debitor], toBucket.onDeposit);
                    if (debtToReallocate > 0) {

                        require(debtToReallocate <= fromBucket.debt[debitor],
                            "Borrower does not have debt to reallocate");
                        require(toBucket.onDeposit > debtToReallocate, "Insufficent liquidity to reallocate");

                        // update accounting of encumbered collateral
                        borrowers[debitor].collateralEncumbered += 
                            wdiv(_amount, toBucket.price) - wdiv(_amount, fromBucket.price);
                        
                        if (toBucket.debt[debitor] == 0 && toBucket.debitorToIndex[debitor] == 0) {
                            toBucket.indexToDebitor[toBucket.totalDebitors] = debitor;
                            toBucket.debitorToIndex[debitor] = toBucket.totalDebitors;
                            toBucket.totalDebitors += 1;
                        }
                        toBucket.debt[debitor] += _amount;
                        toBucket.debtAccumulator += _amount;

                        fromBucket.debt[debitor] -= _amount;
                        if (fromBucket.debt[debitor] == 0) {
                            delete fromBucket.indexToDebitor[fromBucket.debitorToIndex[debitor]];
                            delete fromBucket.debitorToIndex[debitor];
                            fromBucket.totalDebitors -= 1;
                        }
                        fromBucket.debtAccumulator -= _amount;

                        // pay off the moved debt
                        fromBucket.onDeposit += _amount;
                        toBucket.onDeposit -= _amount;

                        if (priceToIndex[fromBucket.price] >= lupIndex) {
                            while (buckets[lupIndex].debtAccumulator == 0) {
                                lupIndex += 1;
                            }
                            pointerToIndex[LOWEST_UTILIZED_PRICE] = lupIndex;
                        }

                        uint256 hupIndex = depositIndex;
                        while (toBucket.onDeposit == 0) {
                            hupIndex -= 1;
                        }
                        pointerToIndex[HIGHEST_UTILIZABLE_PRICE] = hupIndex;
                        
                    }
                    if (toBucket.onDeposit == 0) {
                        break;
                    }
                }

            }
        }

        if (toBucket.onDeposit == 0) {
            return;
        }
        pointerToIndex[HIGHEST_UTILIZABLE_PRICE] = max(pointerToIndex[HIGHEST_UTILIZABLE_PRICE], depositIndex);

    }

    function withdrawQuoteToken(uint256 _amount) external {
    }

    function borrow(uint256 _amount) external {
        require(collateralBalances[msg.sender] > 0, "No colalteral for borrower");
        require(borrowers[msg.sender].collateralEncumbered > collateralBalances[msg.sender],
            "Borrower is already undercollateralized");
        

    }

    function actualUtilization() public view returns (uint256) {
        return 0;
    }

    function targetUtilization() public view returns (uint256) {
        return 0;
    }

    function borrowerInflatorPending() public view returns (uint256 pendingBorrowerInflator) {
        uint256 secondsSinceLastUpdate = block.timestamp - lastBorrowerInflatorUpdate;
        uint256 borrowerSpr = previousRate / SECONDS_PER_YEAR;

        pendingBorrowerInflator = wmul(borrowerInflator, 1 * WAD + (borrowerSpr * secondsSinceLastUpdate));
    }
    
}