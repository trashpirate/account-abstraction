// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MinimalAccount} from "./../src/ethereum/MinimalAccount.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOp is Script {
    function run() public {}

    function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config)
        public
        view
        returns (PackedUserOperation memory)
    {
        // 1. Generate unsigned data
        uint256 nonce = vm.getNonce(config.account);
        PackedUserOperation memory unsignedUserOp = _generateUnsignedUserOperation(callData, config.account, nonce);

        // 2. Get user OpHash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(unsignedUserOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        // 3. Sign the user operation
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(config.account, digest);
        unsignedUserOp.signature = abi.encodePacked(r, s, v);
        return unsignedUserOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16777216; // probably fine - ball park
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeeGas = 256;
        uint128 maxFeePerGas = maxPriorityFeeGas;
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeeGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
