// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MemeFactory} from "../src/MemeFactory.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {IMemeToken} from "../src/IMemeToken.sol";

contract SimpleMintTest is Test {
    MemeFactory public factory;
    address public owner = address(0x123); // Use a valid address
    address public issuer = address(0x456); // Use a valid address
    address public minter = address(0x789); // Use a valid address

    function setUp() public {
        vm.startPrank(owner);
        factory = new MemeFactory(owner);
        vm.stopPrank();
    }

    function test_SimpleMint() public {
        vm.startPrank(issuer);
        vm.deal(issuer, 1 ether);
        
        // Deploy a token with very small amounts
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Simple Test",
            "SIMPLE",
            1000 * 10**18,  // totalSupplyLimit
            100 * 10**18,   // perMint
            1 wei  // very small price (1 wei)
        );
        
        vm.stopPrank();
        
        // Mint tokens
        vm.startPrank(minter);
        vm.deal(minter, 1 ether);
        
        uint256 mintAmount = 1 * 10**18; // 1 token
        uint256 requiredPayment = mintAmount * 1 wei; // 1 wei
        
        factory.mintMeme{value: requiredPayment}(tokenAddress, mintAmount);
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Verify minting
        assertEq(token.balanceOf(minter), mintAmount);
        assertEq(token.minted(), mintAmount);
        
        vm.stopPrank();
    }
}
