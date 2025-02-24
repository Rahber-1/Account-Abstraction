// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "../src/Ethereum/MinimalAccount.sol";
import {DeployMinimal} from "../script/DeployMinimal.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "../script/SendPackedUserOp.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountEth is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    uint256 constant AMOUNT = 1e18;
    address RANDOM_USER = makeAddr("random_user");
    SendPackedUserOp sendPackedUserOp;

    //address owner;

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    function testOwnerCanExecuteCommandsDirectly() public {
        //Arrange
        uint256 balanceMinimalAccount = usdc.balanceOf(address(minimalAccount));
        assertEq(balanceMinimalAccount, 0);
        console.log("balance of minimalAccount:", balanceMinimalAccount);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //Act
        console.log("MinimalAccount owner:", minimalAccount.owner());
        console.log("Sender before prank:", msg.sender);
        vm.prank(minimalAccount.owner());
        console.log("Sender after prank:", msg.sender);

        minimalAccount.execute(dest, value, functionData);

        //Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testRandomUserCanNotExecuteCommand() public {
        //Arrange
        uint256 balanceMinimalAccount = usdc.balanceOf(address(minimalAccount));
        assertEq(balanceMinimalAccount, 0);
        console.log("balance of minimalAccount:", balanceMinimalAccount);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //Act
        vm.prank(RANDOM_USER);
        vm.expectRevert();
        minimalAccount.execute(dest, value, functionData);
    }

    function testRecoverSignedOp() public {
        //Arrange
        uint256 balanceMinimalAccount = usdc.balanceOf(address(minimalAccount));
        assertEq(balanceMinimalAccount, 0);
        console.log("balance of minimalAccount:", balanceMinimalAccount);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executionCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executionCallData, address(minimalAccount), helperConfig.getConfig()
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entrypoint).getUserOpHash(packedUserOp);
        //Act
        address signer = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        //Assert
        assertEq(signer, minimalAccount.owner());
    }

    function testValidateUserOp() public {
        //Arrange
        uint256 balanceMinimalAccount = usdc.balanceOf(address(minimalAccount));
        assertEq(balanceMinimalAccount, 0);
        console.log("balance of minimalAccount:", balanceMinimalAccount);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executionCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executionCallData, address(minimalAccount), helperConfig.getConfig()
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entrypoint).getUserOpHash(packedUserOp);

        //Act
        vm.deal(address(minimalAccount), 2e18); //funds minimalAccount with ETH
        uint256 missingAccountFunds = 1e18;
        vm.prank(helperConfig.getConfig().entrypoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        //Assert
        assertEq(validationData, 0);
    }
}
