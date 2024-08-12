// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "./../src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract Deploy is Script {
    function run() external returns (MinimalAccount, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (address initialOwner) = config.activeNetworkConfig();

        vm.startBroadcast();
        MinimalAccount minimalAccount = new MinimalAccount(initialOwner);
        vm.stopBroadcast();
        return (minimalAccount, config);
    }
}
