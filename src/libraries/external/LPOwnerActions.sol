// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import { Bucket, Lender } from '../../interfaces/pool/commons/IPoolState.sol';

import { MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Maths } from '../internal/Maths.sol';

/**
    @title  LPOwnerActions library
    @notice External library containing logic for LP owners to:
            - increase/decrease/revoke LP allowance; approve/revoke LP transferors; transfer LPs
 */
library LPOwnerActions {

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event ApproveLPTransferors(address indexed lender, address[] transferors);
    event RevokeLPTransferors(address indexed lender, address[] transferors);
    event IncreaseLPAllowance(address indexed owner, address indexed spender, uint256[] indexes, uint256[] amounts);
    event DecreaseLPAllowance(address indexed owner, address indexed spender, uint256[] indexes, uint256[] amounts);
    event RevokeLPAllowance(address indexed owner, address indexed spender, uint256[] indexes);
    event TransferLP(address owner, address newOwner, uint256[] indexes, uint256 lps);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error BucketBankruptcyBlock();
    error InvalidAllowancesInput();
    error InvalidIndex();
    error NoAllowance();
    error TransferorNotApproved();
    error TransferToSameOwner();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev write state:
     *          - increment LPs allowances
     *  @dev reverts on:
     *          - invalid indexes and amounts input InvalidAllowancesInput()
     *  @dev emit events:
     *          - IncreaseLPAllowance
     */
    function increaseLPAllowance(
        mapping(uint256 => uint256) storage allowances_,
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external {
        uint256 indexesLength = indexes_.length;

        if (indexesLength != amounts_.length) revert InvalidAllowancesInput();

        uint256 index;
        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            allowances_[index] += amounts_[i];

            unchecked { ++i; }
        }

        emit IncreaseLPAllowance(
            msg.sender,
            spender_,
            indexes_,
            amounts_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev write state:
     *          - decrement LPs allowances
     *  @dev reverts on:
     *          - invalid indexes and amounts input InvalidAllowancesInput()
     *  @dev emit events:
     *          - DecreaseLPAllowance
     */
    function decreaseLPAllowance(
        mapping(uint256 => uint256) storage allowances_,
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external {
        uint256 indexesLength = indexes_.length;

        if (indexesLength != amounts_.length) revert InvalidAllowancesInput();

        uint256 index;

        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            allowances_[index] -= amounts_[i];

            unchecked { ++i; }
        }

        emit DecreaseLPAllowance(
            msg.sender,
            spender_,
            indexes_,
            amounts_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev write state:
     *          - decrement LPs allowances
     *  @dev emit events:
     *          - RevokeLPAllowance
     */
    function revokeLPAllowance(
        mapping(uint256 => uint256) storage allowances_,
        address spender_,
        uint256[] calldata indexes_
    ) external {
        uint256 indexesLength = indexes_.length;
        uint256 index;

        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            allowances_[index] = 0;

            unchecked { ++i; }
        }

        emit RevokeLPAllowance(
            msg.sender,
            spender_,
            indexes_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev write state:
     *          - approvedTransferors mapping
     *  @dev emit events:
     *          - ApproveLPTransferors
     */
    function approveLPTransferors(
        mapping(address => bool) storage allowances_,
        address[] calldata transferors_
    ) external  {
        uint256 transferorsLength = transferors_.length;
        for (uint256 i = 0; i < transferorsLength; ) {
            allowances_[transferors_[i]] = true;

            unchecked { ++i; }
        }

        emit ApproveLPTransferors(
            msg.sender,
            transferors_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev write state:
     *          - approvedTransferors mapping
     *  @dev emit events:
     *          - RevokeLPTransferors
     */
    function revokeLPTransferors(
        mapping(address => bool) storage allowances_,
        address[] calldata transferors_
    ) external  {
        uint256 transferorsLength = transferors_.length;
        for (uint256 i = 0; i < transferorsLength; ) {
            delete allowances_[transferors_[i]];

            unchecked { ++i; }
        }

        emit RevokeLPTransferors(
            msg.sender,
            transferors_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev write state:
     *          - delete allowance mapping
     *          - increment new lender.lps accumulator and lender.depositTime state
     *          - delete old lender from bucket -> lender mapping
     *  @dev reverts on:
     *          - invalid index InvalidIndex()
     *          - no allowance NoAllowance()
     *  @dev emit events:
     *          - TransferLP
     */
    function transferLP(
        mapping(uint256 => Bucket) storage buckets_,
        mapping(address => mapping(address => mapping(uint256 => uint256))) storage allowances_,
        mapping(address => mapping(address => bool)) storage approvedTransferors_,
        address ownerAddress_,
        address newOwnerAddress_,
        uint256[] calldata indexes_
    ) external {
        // revert if msg.sender is not the new owner and is not approved as a transferor by the new owner
        if (newOwnerAddress_ != msg.sender && !approvedTransferors_[newOwnerAddress_][msg.sender]) revert TransferorNotApproved();

        // revert if new owner address is the same as old owner address
        if (ownerAddress_ == newOwnerAddress_) revert TransferToSameOwner();

        uint256 indexesLength = indexes_.length;
        uint256 index;
        uint256 lpsTransferred;

        for (uint256 i = 0; i < indexesLength; ) {
            index = indexes_[i];

            // revert if invalid index
            if (index > MAX_FENWICK_INDEX) revert InvalidIndex();

            Bucket storage bucket = buckets_[index];
            Lender storage owner  = bucket.lenders[ownerAddress_];

            uint256 bankruptcyTime   = bucket.bankruptcyTime;
            uint256 ownerDepositTime = owner.depositTime;
            uint256 ownerLpBalance   = bankruptcyTime < ownerDepositTime ? owner.lps : 0;

            uint256 allowedAmount = allowances_[ownerAddress_][newOwnerAddress_][index];
            if (allowedAmount == 0) revert NoAllowance();

            // transfer allowed amount or entire LP balance
            allowedAmount = Maths.min(allowedAmount, ownerLpBalance);

            // move owner lps (if any) to the new owner
            if (allowedAmount != 0) {
                Lender storage newOwner = bucket.lenders[newOwnerAddress_];

                uint256 newOwnerDepositTime = newOwner.depositTime;

                if (newOwnerDepositTime > bankruptcyTime) {
                    // deposit happened in a healthy bucket, add amount of LPs to new owner
                    newOwner.lps += allowedAmount;
                } else {
                    // bucket bankruptcy happened after deposit, reset balance and add amount of LPs to new owner
                    newOwner.lps = allowedAmount;
                }

                owner.lps      -= allowedAmount; // remove amount of LPs from old owner
                lpsTransferred += allowedAmount; // add amount of LPs to total LPs transferred

                // set the deposit time as the max of transferred deposit and current deposit time
                newOwner.depositTime = Maths.max(ownerDepositTime, newOwnerDepositTime);
            }

            // reset allowances of transferred LPs
            delete allowances_[ownerAddress_][newOwnerAddress_][index];

            unchecked { ++i; }
        }

        emit TransferLP(
            ownerAddress_,
            newOwnerAddress_,
            indexes_,
            lpsTransferred
        );
    }
}
