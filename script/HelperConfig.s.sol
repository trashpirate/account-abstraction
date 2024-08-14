// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EntryPoint} from "account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    // types
    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    // helpers
    uint256 constant CONSTANT = 0;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 111555111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    address constant WALLET = 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF;
    address constant ANVIL_DEFAULT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // chain configurations
    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    // errors
    error HelperConfig__InvalidChainId();

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return getAnvilConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF, account: WALLET});
    }

    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: WALLET});
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.account != address(0)) {
            return activeNetworkConfig;
        }

        // deploy mocks
        console.log("Deploying mocks...");
        vm.startBroadcast(ANVIL_DEFAULT);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        return NetworkConfig({entryPoint: address(entryPoint), account: ANVIL_DEFAULT});
    }
}
