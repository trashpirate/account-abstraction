// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EntryPoint} from "account-abstraction/contracts/core/EntryPoint.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address entryPoint;
        address account;
        address usdc;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 111555111;
    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant ARB_SEPOLIA_CHAIN_ID = 421614;
    uint256 constant ARB_MAINNET_CHAIN_ID = 42161;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    uint256 constant FORK_CHAIN_ID = 1234;

    // chain configurations
    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getEthMainnetConfig();
        networkConfigs[ARB_SEPOLIA_CHAIN_ID] = getArbSepoliaConfig();
        networkConfigs[ARB_MAINNET_CHAIN_ID] = getArbMainnetConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncSepoliaConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncMainnetConfig();
        networkConfigs[FORK_CHAIN_ID] = getEthMainnetConfig();
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

    /*//////////////////////////////////////////////////////////////
                                CONFIGS
    //////////////////////////////////////////////////////////////*/

    function getEthSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            account: vm.envAddress("TEST_WALLET"),
            usdc: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
        });
    }

    function getEthMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            account: vm.envAddress("TEST_WALLET"),
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        });
    }

    function getArbSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            account: vm.envAddress("TEST_WALLET"),
            usdc: 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d
        });
    }

    function getArbMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            account: vm.envAddress("TEST_WALLET"),
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
        });
    }

    function getZkSyncSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0),
            account: vm.envAddress("TEST_WALLET"),
            usdc: 0xAe045DE5638162fa134807Cb558E15A3F5A7F853
        });
    }

    function getZkSyncMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0),
            account: vm.envAddress("TEST_WALLET"),
            usdc: 0x80b5E2393E14c91554e9CCC9FB43cD948957FfBF
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.account != address(0)) {
            return activeNetworkConfig;
        }

        // deploy mocks
        console.log("Deploying mocks...");
        vm.startBroadcast(vm.envAddress("ANVIL_DEFAULT_ACCOUNT"));
        EntryPoint entryPoint = new EntryPoint();
        ERC20Mock usdc = new ERC20Mock();
        vm.stopBroadcast();
        console.log("Mocks deployed.");

        activeNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            account: vm.envAddress("ANVIL_DEFAULT_ACCOUNT"),
            usdc: address(usdc)
        });
        return activeNetworkConfig;
    }
}
