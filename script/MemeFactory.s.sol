// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MemeFactory} from "../src/MemeFactory.sol";

contract MemeFactoryScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        
        // Get Uniswap V2 Router address from environment or use a default
        // For mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // For testnets, you may need to deploy a mock or use the actual router
        address routerAddress = vm.envOr("UNISWAP_V2_ROUTER", address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        
        // Deploy MemeFactory
        MemeFactory factory = new MemeFactory(msg.sender, routerAddress);
        console.log("MemeFactory deployed at:", address(factory));
        console.log("Implementation deployed at:", factory.implementation());
        console.log("Uniswap V2 Router:", address(factory.uniswapV2Router()));
        
        vm.stopBroadcast();
    }
}
