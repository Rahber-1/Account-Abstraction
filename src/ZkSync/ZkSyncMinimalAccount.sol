// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// zkSync Era Imports
import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from
    "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {Utils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";

// OZ Imports
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ZkSyncMinimalAccount is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    /*////////////////////////////////////////////////////////////////
                        ERRORS                                       
    ////////////////////////////////////////////////////////////////*/
    error ZkSyncMinimalAccount__NotEnoughBalance();
    error ZkSyncMinimalAccount__NotFromBootLoaderOrOwner();
    error ZkSyncMinimalAccount__ExecutionFailed();
    error ZkSyncMinimalAccount__ValidationFailed();

    constructor() Ownable(msg.sender) {}
    receive() external payable {}

    /*/////////////////////////////////////////////////////////////
                      MODIFIERS                                  
    /////////////////////////////////////////////////////////////*/
    modifier requiredFromBootLoaderOrOwner() {
        if (msg.sender != address(BOOTLOADER_FORMAL_ADDRESS) && msg.sender != owner()) {
            revert ZkSyncMinimalAccount__NotFromBootLoaderOrOwner();
        }
        _;
    }
    modifier requiredFromBootLoader() {
        if (msg.sender != address(BOOTLOADER_FORMAL_ADDRESS)) {
            revert ZkSyncMinimalAccount__NotFromBootLoaderOrOwner();
        }
        _;
    }

    /*////////////////////////////////////////////////////////////////
                         EXTERNAL FUNCTIONS
    ////////////////////////////////////////////////////////////////*/

    function validateTransaction(
        bytes32 /*_txHash*/, 
        bytes32 /*_suggestedSignedHash*/, 
        Transaction calldata _transaction
    ) external payable requiredFromBootLoader returns (bytes4 magic) {
        return _validateTransaction(_transaction);
    }

    function executeTransaction(
        bytes32 /*_txHash*/, 
        bytes32 /*_suggestedSignedHash*/, 
        Transaction calldata _transaction
    ) external payable requiredFromBootLoaderOrOwner {
        _executeTransaction(_transaction);
    }

    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {
        bytes4 magic = _validateTransaction(_transaction);
        if (magic != ACCOUNT_VALIDATION_SUCCESS_MAGIC) {
            revert ZkSyncMinimalAccount__ValidationFailed();
        }
        _executeTransaction(_transaction);
    }

    function payForTransaction(
        bytes32 /*_txHash*/, 
        bytes32 /*_suggestedSignedHash*/, 
        Transaction calldata _transaction
    ) external payable {
        bool success = _transaction.payToTheBootloader();
        if (!success) {
            revert ZkSyncMinimalAccount__NotEnoughBalance();
        }
    }

    function prepareForPaymaster(
        bytes32 /*_txHash*/, 
        bytes32 /*_possibleSignedHash*/, 
        Transaction calldata _transaction
    ) external payable {}

    /*//////////////////////////////////////////////////
                     INTERNAL FUNCTIONS          
    //////////////////////////////////////////////////*/

    function _validateTransaction(Transaction memory _transaction) internal returns (bytes4 magic) {
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );

        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        if (totalRequiredBalance > address(this).balance) {
            revert ZkSyncMinimalAccount__NotEnoughBalance();
        }

        bytes32 txHash = _transaction.encodeHash();
        address signer = ECDSA.recover(txHash, _transaction.signature);
        bool isValid = signer == owner();
        
        return isValid ? ACCOUNT_VALIDATION_SUCCESS_MAGIC : bytes4(0);
    }

    function _executeTransaction(Transaction memory _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;
        
        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gas = Utils.safeCastToU32(gasleft());
            SystemContractsCaller.systemCallWithPropagatedRevert(gas, to, value, data);
        } else {
            bool success;
            assembly ("memory-safe") {
                let ptr := mload(0x40)
                let dataSize := mload(data)
                let dataPtr := add(data, 0x20)
                success := call(gas(), to, value, dataPtr, dataSize, 0, 0)
                mstore(0x40, add(ptr, 0x20)) // Update free memory pointer
            }
            if (!success) {
                revert ZkSyncMinimalAccount__ExecutionFailed();
            }
        }
    }
}
