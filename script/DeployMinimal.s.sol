// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MinimalAccount} from "../src/Ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";

contract DeployMinimal is Script {
    function run() public {
        // Deployment logic
    }

    function deployMinimalAccount() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Specify the EntryPoint address for Sepolia
        address entryPointAddress = 0xC03Aac639Bb21233e0139381970328dB8bcEeB67;

        // Start broadcasting with the specified account
        vm.startBroadcast(config.account);

        // Deploy the MinimalAccount contract with the EntryPoint address
        MinimalAccount minimalAccount = new MinimalAccount(entryPointAddress);

        // Transfer ownership to the specified account
        minimalAccount.transferOwnership(config.account);

        // Stop broadcasting
        vm.stopBroadcast();

        return (helperConfig, minimalAccount);
    }
}
