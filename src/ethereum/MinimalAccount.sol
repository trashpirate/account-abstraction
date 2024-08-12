// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * IMPORTS
 */
import {IAccount} from "account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/contracts/core/Helpers.sol";
/**
 * INTERFACES
 */

/**
 * LIBRARIES
 */

/**
 * @title
 * @author Nadina Oates
 * @notice ERC-4337
 */
contract MinimalAccount is IAccount, Ownable {
    /**
     * TYPES
     */

    /**
     * STATE VARIABLES
     */

    /**
     * EVENTS
     */

    /**
     * ERRORS
     */

    /**
     * MODIFIERS
     */

    /**
     * CONSTRUCTOR
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * RECEIVE/FALLBACK
     */

    /**
     * EXTERNAL
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        // signature is valid if it is contract owner (0: valid, 1: not valid)
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNonce()
        _payPrefund(missingAccountFunds);
    }

    /**
     * PUBLIC
     */

    /**
     * INTERNAL
     */

    // EIP-191 version of the signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }
    /**
     * PRIVATE
     */
}
