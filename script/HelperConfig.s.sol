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
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;

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

    function getZkSyncSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0),
            account: vm.envAddress("TEST_WALLET"),
            usdc: 0xAe045DE5638162fa134807Cb558E15A3F5A7F853
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
