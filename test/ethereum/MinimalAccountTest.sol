// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;

    ERC20Mock usdc;
    uint256 constant AMOUNT = 1e18;

    address USER = makeAddr("user");

    function setUp() external virtual {
        DeployMinimalAccount deployMinimalAccount = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployMinimalAccount.deployMinimalAccount();

        usdc = new ERC20Mock();
    }

    /// USDC approval:
    /// msg.sender -> MinimalAccount
    /// approve some amount
    /// USDC contract
    /// come from the Entry Point

    function test__OwnerCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        // Act
        vm.startPrank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);
        vm.stopPrank();

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function test__Revert__NotOwnerCannotExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);

        // Act
        vm.prank(USER);
        minimalAccount.execute(dest, value, functionData);
    }
}
