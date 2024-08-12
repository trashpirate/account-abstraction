// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * IMPORTS
 */
import {IAccount} from "account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
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
contract MinimalAccount is IAccount {
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
    constructor(address owner) {}

    /**
     * RECEIVE/FALLBACK
     */

    /**
     * EXTERNAL
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {}

    /**
     * PUBLIC
     */

    /**
     * INTERNAL
     */

    /**
     * PRIVATE
     */
}
