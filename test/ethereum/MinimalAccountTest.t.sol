// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {SendPackedUserOp, PackedUserOperation} from "script/SendPackedUserOp.s.sol";

// foundry devops imports
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

// openzeppelin imports
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// account abstraction imports
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccountTest is Test, ZkSyncChainChecker {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;

    ERC20Mock usdc;

    SendPackedUserOp sendPackedUserOp;
    uint256 constant AMOUNT = 1e18;

    address payable RANDOM_USER = payable(makeAddr("random-user"));

    function setUp() external skipZkSync {
        DeployMinimalAccount deployMinimalAccount = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployMinimalAccount.deployMinimalAccount();

        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function test__Constructor() public skipZkSync {
        // Arrange
        address entryPoint = makeAddr("entry-point");

        // Act
        MinimalAccount newAccount = new MinimalAccount(entryPoint);

        // Assert
        assertEq(newAccount.getEntryPoint(), entryPoint);
    }
    /*//////////////////////////////////////////////////////////////
                                 GETTERS
    //////////////////////////////////////////////////////////////*/

    function test__Getters() public skipZkSync {
        // Arrange
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Act
        address entryPoint = minimalAccount.getEntryPoint();

        // Assert
        assertEq(config.entryPoint, entryPoint);
    }

    /*//////////////////////////////////////////////////////////////
                                EXECTUTE
    //////////////////////////////////////////////////////////////*/

    /// USDC approval:
    /// msg.sender -> MinimalAccount
    /// approve some amount
    /// USDC contract
    /// come from the Entry Point

    function test__OwnerCanExecuteCommands() public skipZkSync {
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

    function test__Revert__NotOwnerCannotExecuteCommands() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);

        // Act
        vm.prank(RANDOM_USER);
        minimalAccount.execute(dest, value, functionData);
    }

    function test__Revert__CallFails() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        address owner = minimalAccount.owner();

        vm.mockCallRevert(dest, value, functionData, "");
        vm.expectRevert(abi.encodeWithSelector(MinimalAccount.MinimalAccount__CallFailed.selector, ""));

        // Act
        vm.prank(owner);
        minimalAccount.execute(dest, value, functionData);
    }

    /*//////////////////////////////////////////////////////////////
                             SIGN OPERATION
    //////////////////////////////////////////////////////////////*/

    function test__RecoverSignedOps() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        // Act
        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        // Assert
        assertEq(actualSigner, minimalAccount.owner());
    }

    function test__Revert__CannotRecoverSignedByRandomOps() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedByRandomUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        // Act
        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        // Assert
        assertNotEq(actualSigner, minimalAccount.owner());
    }

    /*//////////////////////////////////////////////////////////////
                          VALIDATE OPERATION
    //////////////////////////////////////////////////////////////*/
    // 1. Sign user op
    // 2. Call validate user op
    // 3. Check if the user op is valid
    function test__ValidationUserOpsSuccessful() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        // Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, 0);

        // Assert
        assertEq(validationData, 0);
    }

    function test__ValidationUserOpsFails() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedByRandomUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        // Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, 0);

        // Assert
        assertEq(validationData, 1);
    }

    function test__ValidationUserOpsWithRefund() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;
        vm.deal(address(minimalAccount), missingAccountFunds);

        // Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        // Assert
        assertEq(validationData, 0);
    }

    function test__Revert__ValidationUserOpsWithInsufficientFunds() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        address entryPointAddress = helperConfig.getConfig().entryPoint;
        vm.expectRevert(MinimalAccount.MinimalAccount__InsufficientFunds.selector);

        // Act
        vm.prank(entryPointAddress);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        // Assert
        assertEq(validationData, 0);
    }

    function test__Revert__ValidationUserOpsWithFailedPrefund() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;
        vm.deal(address(minimalAccount), missingAccountFunds);

        address entryPointAddress = helperConfig.getConfig().entryPoint;
        vm.expectRevert(abi.encodeWithSelector(MinimalAccount.MinimalAccount__PreFundFailed.selector, ""));

        vm.mockCallRevert(entryPointAddress, missingAccountFunds, "", "");

        // Act
        vm.prank(entryPointAddress);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        // Assert
        assertEq(validationData, 0);
    }

    function test__Revert__CannotValidateUserOpsIfNotEntryPoint() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;
        vm.deal(address(minimalAccount), missingAccountFunds);

        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPoint.selector);

        // Act
        vm.prank(RANDOM_USER);
        minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);
    }

    /*//////////////////////////////////////////////////////////////
                      ENTRY POINT CAN EXECUTE
    //////////////////////////////////////////////////////////////*/
    function test__EntryPointCanExectueCommands() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );

        vm.deal(address(minimalAccount), 1e18);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        // Act
        vm.prank(RANDOM_USER);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, RANDOM_USER);

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function test__Revert__EntryPointCannotExectueUnsignedCommands() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedByRandomUserOperation(
            executeCalldata, helperConfig.getConfig(), address(minimalAccount)
        );

        vm.deal(address(minimalAccount), 1e18);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        address entryPoint = helperConfig.getConfig().entryPoint;

        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOp.selector, 0, "AA24 signature error"));

        // Act
        vm.prank(RANDOM_USER);
        IEntryPoint(entryPoint).handleOps(ops, RANDOM_USER);
    }
}
