// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MemeFactory} from "../src/MemeFactory.sol";

contract MemeFactoryScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        
        // Deploy MemeFactory
        MemeFactory factory = new MemeFactory(msg.sender);
        console.log("MemeFactory deployed at:", address(factory));
        console.log("Implementation deployed at:", factory.implementation());
        
        vm.stopBroadcast();
    }
}
