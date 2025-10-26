// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {MemeFactory} from "../src/MemeFactory.sol";

contract MemeFactoryTest is Test {
    MemeFactory public factory;
    MemeToken public implementation;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        factory = new MemeFactory(owner);
        implementation = MemeToken(factory.implementation());
        vm.stopPrank();
    }

    function test_FactoryDeployment() public {
        assertTrue(address(factory) != address(0));
        assertTrue(address(implementation) != address(0));
        assertEq(factory.owner(), owner);
        assertEq(factory.tokenCount(), 0);
    }

    function test_CreateToken() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Test Meme", "TEST");
        
        assertTrue(tokenAddress != address(0));
        assertEq(factory.tokenCount(), 1);
        
        MemeToken token = MemeToken(tokenAddress);
        assertEq(token.name(), "Test Meme");
        assertEq(token.symbol(), "TEST");
        assertEq(token.owner(), user1);
        assertEq(token.totalSupply(), 100_000_000 * 10**18);
        
        vm.stopPrank();
    }

    function test_CreateTokenWithBurn() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Burn Token", "BURN");
        MemeToken token = MemeToken(tokenAddress);
        
        // Test transfer with burn
        uint256 transferAmount = 1000 * 10**18;
        uint256 expectedBurn = (transferAmount * 100) / 10000; // 1% burn
        uint256 expectedTransfer = transferAmount - expectedBurn;
        
        token.transfer(user2, transferAmount);
        
        assertEq(token.balanceOf(user1), 100_000_000 * 10**18 - transferAmount);
        assertEq(token.balanceOf(user2), expectedTransfer);
        assertEq(token.totalSupply(), 100_000_000 * 10**18 - expectedBurn);
        
        vm.stopPrank();
    }

    function test_SymbolUniqueness() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        factory.createTokenWithDefaults{value: 0.01 ether}("First Token", "UNIQUE");
        
        // Try to create another token with same symbol
        vm.expectRevert("Symbol already exists");
        factory.createTokenWithDefaults{value: 0.01 ether}("Second Token", "UNIQUE");
        
        vm.stopPrank();
    }

    function test_InsufficientFee() public {
        vm.startPrank(user1);
        vm.deal(user1, 0.005 ether);
        
        vm.expectRevert("Insufficient creation fee");
        factory.createTokenWithDefaults{value: 0.005 ether}("Test Token", "TEST");
        
        vm.stopPrank();
    }

    function test_GetTokenInfo() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Info Token", "INFO");
        
        MemeFactory.TokenInfo memory tokenInfo = factory.getTokenInfo(1);
        
        assertEq(tokenInfo.tokenAddress, tokenAddress);
        assertEq(tokenInfo.name, "Info Token");
        assertEq(tokenInfo.symbol, "INFO");
        assertEq(tokenInfo.creator, user1);
        assertTrue(tokenInfo.exists);
        assertTrue(tokenInfo.createdAt > 0);
        
        vm.stopPrank();
    }

    function test_GetTokensByCreator() public {
        vm.startPrank(user1);
        vm.deal(user1, 2 ether);
        
        factory.createTokenWithDefaults{value: 0.01 ether}("Token 1", "TKN1");
        factory.createTokenWithDefaults{value: 0.01 ether}("Token 2", "TKN2");
        
        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.deal(user2, 1 ether);
        
        factory.createTokenWithDefaults{value: 0.01 ether}("Token 3", "TKN3");
        
        vm.stopPrank();
        
        uint256[] memory user1Tokens = factory.getTokensByCreator(user1);
        uint256[] memory user2Tokens = factory.getTokensByCreator(user2);
        
        assertEq(user1Tokens.length, 2);
        assertEq(user2Tokens.length, 1);
        assertEq(user1Tokens[0], 1);
        assertEq(user1Tokens[1], 2);
        assertEq(user2Tokens[0], 3);
    }

    function test_OwnerFunctions() public {
        vm.startPrank(owner);
        
        // Test setting creation fee
        factory.setCreationFee(0.02 ether);
        assertEq(factory.creationFee(), 0.02 ether);
        
        // Test pause/unpause
        factory.pause();
        assertTrue(factory.paused());
        
        factory.unpause();
        assertFalse(factory.paused());
        
        vm.stopPrank();
    }

    function test_NonOwnerCannotSetFee() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        factory.setCreationFee(0.02 ether);
        
        vm.stopPrank();
    }

    function test_Withdraw() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        factory.createTokenWithDefaults{value: 0.01 ether}("Test Token", "TEST");
        
        vm.stopPrank();
        
        // Create a payable address for owner
        address payable ownerPayable = payable(owner);
        uint256 balanceBefore = ownerPayable.balance;
        
        vm.startPrank(owner);
        
        factory.withdraw();
        
        assertEq(ownerPayable.balance, balanceBefore + 0.01 ether);
        
        vm.stopPrank();
    }

    function test_SymbolAvailability() public {
        assertTrue(factory.isSymbolAvailable("NEW"));
        
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        factory.createTokenWithDefaults{value: 0.01 ether}("Test Token", "NEW");
        
        assertFalse(factory.isSymbolAvailable("NEW"));
        
        vm.stopPrank();
    }

    function test_RefundExcessPayment() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        uint256 balanceBefore = user1.balance;
        
        factory.createTokenWithDefaults{value: 0.05 ether}("Test Token", "TEST");
        
        // Should refund 0.04 ether (0.05 - 0.01)
        assertEq(user1.balance, balanceBefore - 0.01 ether);
        
        vm.stopPrank();
    }
}
