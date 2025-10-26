// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {MemeFactory} from "../src/MemeFactory.sol";

contract MemeTokenPhase2Test is Test {
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

    function test_InitializeFunction() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createToken{value: 0.01 ether}(
            "Test Meme",
            "TEST",
            1_000_000 * 10**18, // totalSupplyLimit
            100_000 * 10**18,   // perMint
            0.001 ether         // price
        );
        
        MemeToken token = MemeToken(tokenAddress);
        
        // Test token info
        assertEq(token.name(), "Test Meme");
        assertEq(token.symbol(), "TEST");
        assertEq(token.owner(), user1);
        assertEq(token.issuer(), user1);
        assertEq(token.totalSupplyLimit(), 1_000_000 * 10**18);
        assertEq(token.perMint(), 100_000 * 10**18);
        assertEq(token.price(), 0.001 ether);
        assertEq(token.minted(), 0);
        assertEq(token.factory(), address(factory));
        
        vm.stopPrank();
    }

    function test_InitializeCannotBeCalledTwice() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Test Meme", "TEST");
        MemeToken token = MemeToken(tokenAddress);
        
        // Try to initialize again - should fail
        vm.expectRevert("Initializable: contract is already initialized");
        token.initialize(
            "New Name",
            "NEW",
            user1,
            address(factory),
            1_000_000 * 10**18,
            100_000 * 10**18,
            0.001 ether
        );
        
        vm.stopPrank();
    }

    function test_MintByFactoryOnlyFactoryCanCall() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Test Meme", "TEST");
        MemeToken token = MemeToken(tokenAddress);
        
        // Try to mint from non-factory address - should fail
        vm.expectRevert("Only factory can call this function");
        token.mintByFactory(user2, 1000 * 10**18);
        
        vm.stopPrank();
    }

    function test_MintByFactorySuccess() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createToken{value: 0.01 ether}(
            "Test Meme",
            "TEST",
            1_000_000 * 10**18, // totalSupplyLimit
            100_000 * 10**18,   // perMint
            0.001 ether         // price
        );
        
        vm.stopPrank();
        
        // Factory mints tokens
        vm.startPrank(owner);
        factory.mintToken(tokenAddress, user2, 50_000 * 10**18);
        
        MemeToken token = MemeToken(tokenAddress);
        assertEq(token.balanceOf(user2), 50_000 * 10**18);
        assertEq(token.minted(), 50_000 * 10**18);
        assertEq(token.totalSupply(), 50_000 * 10**18);
        
        vm.stopPrank();
    }

    function test_MintByFactoryWithDefaultAmount() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createToken{value: 0.01 ether}(
            "Test Meme",
            "TEST",
            1_000_000 * 10**18, // totalSupplyLimit
            100_000 * 10**18,   // perMint
            0.001 ether         // price
        );
        
        vm.stopPrank();
        
        // Factory mints tokens with default perMint amount
        vm.startPrank(owner);
        factory.mintToken(tokenAddress, user2, 0); // 0 means use default perMint
        
        MemeToken token = MemeToken(tokenAddress);
        assertEq(token.balanceOf(user2), 100_000 * 10**18); // default perMint
        assertEq(token.minted(), 100_000 * 10**18);
        
        vm.stopPrank();
    }

    function test_MintExceedsTotalSupplyLimit() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createToken{value: 0.01 ether}(
            "Test Meme",
            "TEST",
            100_000 * 10**18,   // totalSupplyLimit
            100_000 * 10**18,   // perMint
            0.001 ether         // price
        );
        
        vm.stopPrank();
        
        // Factory tries to mint more than total supply limit
        vm.startPrank(owner);
        vm.expectRevert("Exceeds total supply limit");
        factory.mintToken(tokenAddress, user2, 200_000 * 10**18);
        
        vm.stopPrank();
    }

    function test_GetTokenInfo() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createToken{value: 0.01 ether}(
            "Test Meme",
            "TEST",
            1_000_000 * 10**18, // totalSupplyLimit
            100_000 * 10**18,   // perMint
            0.001 ether         // price
        );
        
        MemeToken token = MemeToken(tokenAddress);
        
        (
            string memory name_,
            string memory symbol_,
            uint256 totalSupply_,
            uint256 totalSupplyLimit_,
            uint256 perMint_,
            uint256 price_,
            address issuer_,
            uint256 minted_
        ) = token.getTokenInfo();
        
        assertEq(name_, "Test Meme");
        assertEq(symbol_, "TEST");
        assertEq(totalSupply_, 0);
        assertEq(totalSupplyLimit_, 1_000_000 * 10**18);
        assertEq(perMint_, 100_000 * 10**18);
        assertEq(price_, 0.001 ether);
        assertEq(issuer_, user1);
        assertEq(minted_, 0);
        
        vm.stopPrank();
    }

    function test_CanMintAndGetRemainingMintable() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createToken{value: 0.01 ether}(
            "Test Meme",
            "TEST",
            1_000_000 * 10**18, // totalSupplyLimit
            100_000 * 10**18,   // perMint
            0.001 ether         // price
        );
        
        MemeToken token = MemeToken(tokenAddress);
        
        // Initially can mint
        assertTrue(token.canMint());
        assertEq(token.getRemainingMintable(), 1_000_000 * 10**18);
        
        vm.stopPrank();
        
        // Mint some tokens
        vm.startPrank(owner);
        factory.mintToken(tokenAddress, user2, 300_000 * 10**18);
        
        assertTrue(token.canMint());
        assertEq(token.getRemainingMintable(), 700_000 * 10**18);
        
        // Mint remaining tokens
        factory.mintToken(tokenAddress, user2, 700_000 * 10**18);
        
        assertFalse(token.canMint());
        assertEq(token.getRemainingMintable(), 0);
        
        vm.stopPrank();
    }

    function test_OwnerFunctions() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Test Meme", "TEST");
        MemeToken token = MemeToken(tokenAddress);
        
        // Test setting price
        token.setPrice(0.002 ether);
        assertEq(token.price(), 0.002 ether);
        
        // Test setting perMint
        token.setPerMint(200_000 * 10**18);
        assertEq(token.perMint(), 200_000 * 10**18);
        
        // Test setting burn rate
        token.setBurnRate(200); // 2%
        assertEq(token.burnRate(), 200);
        
        // Test toggling burn
        token.toggleBurn(false);
        assertFalse(token.burnEnabled());
        
        vm.stopPrank();
    }

    function test_NonOwnerCannotCallOwnerFunctions() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Test Meme", "TEST");
        MemeToken token = MemeToken(tokenAddress);
        
        vm.stopPrank();
        
        // Try to call owner functions from non-owner
        vm.startPrank(user2);
        
        vm.expectRevert();
        token.setPrice(0.002 ether);
        
        vm.expectRevert();
        token.setPerMint(200_000 * 10**18);
        
        vm.expectRevert();
        token.setBurnRate(200);
        
        vm.expectRevert();
        token.toggleBurn(false);
        
        vm.stopPrank();
    }

    function test_FactoryDefaultParameters() public {
        vm.startPrank(owner);
        
        // Get default parameters
        (uint256 totalSupplyLimit, uint256 perMint, uint256 price) = factory.getDefaultParameters();
        
        assertEq(totalSupplyLimit, 1_000_000_000 * 10**18);
        assertEq(perMint, 100_000_000 * 10**18);
        assertEq(price, 0.001 ether);
        
        // Set new default parameters
        factory.setDefaultParameters(
            2_000_000_000 * 10**18, // new totalSupplyLimit
            200_000_000 * 10**18,   // new perMint
            0.002 ether             // new price
        );
        
        (totalSupplyLimit, perMint, price) = factory.getDefaultParameters();
        assertEq(totalSupplyLimit, 2_000_000_000 * 10**18);
        assertEq(perMint, 200_000_000 * 10**18);
        assertEq(price, 0.002 ether);
        
        vm.stopPrank();
    }

    function test_CreateTokenWithCustomParameters() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createToken{value: 0.01 ether}(
            "Custom Meme",
            "CUSTOM",
            500_000 * 10**18,   // custom totalSupplyLimit
            50_000 * 10**18,    // custom perMint
            0.005 ether         // custom price
        );
        
        MemeToken token = MemeToken(tokenAddress);
        
        assertEq(token.totalSupplyLimit(), 500_000 * 10**18);
        assertEq(token.perMint(), 50_000 * 10**18);
        assertEq(token.price(), 0.005 ether);
        
        vm.stopPrank();
    }

    function test_CreateTokenWithDefaultParameters() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.createTokenWithDefaults{value: 0.01 ether}("Default Meme", "DEFAULT");
        
        MemeToken token = MemeToken(tokenAddress);
        
        // Should use factory default parameters
        assertEq(token.totalSupplyLimit(), 1_000_000_000 * 10**18);
        assertEq(token.perMint(), 100_000_000 * 10**18);
        assertEq(token.price(), 0.001 ether);
        
        vm.stopPrank();
    }
}
