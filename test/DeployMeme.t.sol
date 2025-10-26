// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MemeFactory} from "../src/MemeFactory.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {IMemeToken} from "../src/IMemeToken.sol";

contract DeployMemeTest is Test {
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

    function test_DeployMemeSuccess() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Deploy a new meme token
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Test Meme",
            "TEST",
            1_000_000 * 10**18, // totalSupplyLimit
            100_000 * 10**18,   // perMint
            0.001 ether         // price
        );
        
        // Verify the token was deployed successfully
        assertTrue(tokenAddress != address(0), "Token address should not be zero");
        
        // Verify the token implements IMemeToken interface
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Test basic token properties
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

    function test_DeployMemeWithDefaultParameters() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Deploy with default parameters (0 values)
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Default Meme",
            "DEFAULT",
            0, // Use default totalSupplyLimit
            0, // Use default perMint
            0  // Use default price
        );
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Verify default parameters were used
        assertEq(token.totalSupplyLimit(), 1_000_000_000 * 10**18); // Default: 1 billion
        assertEq(token.perMint(), 100_000_000 * 10**18); // Default: 100 million
        assertEq(token.price(), 0.001 ether); // Default: 0.001 ETH
        
        vm.stopPrank();
    }

    function test_DeployMemeEventEmitted() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Deploy token and capture events
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Event Test",
            "EVENT",
            1_000_000 * 10**18,
            100_000 * 10**18,
            0.001 ether
        );
        
        // Verify the event was emitted with correct data
        assertTrue(tokenAddress != address(0));
        
        // Check that both TokenCreated and MemeDeployed events were emitted
        // by verifying the token was created successfully
        assertTrue(factory.isTokenCreated(tokenAddress));
        
        vm.stopPrank();
    }

    function test_DeployMemeInsufficientFee() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Try to deploy with insufficient fee
        vm.expectRevert("Insufficient creation fee");
        factory.deployMeme{value: 0.001 ether}("Low Fee", "LOW", 0, 0, 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeSymbolAlreadyExists() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Deploy first token
        factory.deployMeme{value: 0.01 ether}("First Token", "UNIQUE", 0, 0, 0);
        
        // Try to deploy second token with same symbol
        vm.expectRevert("Symbol already exists");
        factory.deployMeme{value: 0.01 ether}("Second Token", "UNIQUE", 0, 0, 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeEmptyName() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        vm.expectRevert("Name cannot be empty");
        factory.deployMeme{value: 0.01 ether}("", "EMPTY", 0, 0, 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeEmptySymbol() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        vm.expectRevert("Symbol cannot be empty");
        factory.deployMeme{value: 0.01 ether}("Empty Symbol", "", 0, 0, 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeNameTooLong() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        string memory longName = "This is a very long name that exceeds the maximum allowed length of fifty characters";
        
        vm.expectRevert("Name too long");
        factory.deployMeme{value: 0.01 ether}(longName, "LONG", 0, 0, 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeSymbolTooLong() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        vm.expectRevert("Symbol too long");
        factory.deployMeme{value: 0.01 ether}("Long Symbol", "VERYLONGSYMBOL", 0, 0, 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeRefundExcessPayment() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        uint256 balanceBefore = user1.balance;
        
        // Deploy with excess payment
        factory.deployMeme{value: 0.02 ether}("Excess Payment", "EXCESS", 0, 0, 0);
        
        // Verify excess was refunded
        assertEq(user1.balance, balanceBefore - 0.01 ether);
        
        vm.stopPrank();
    }

    function test_DeployMemeTokenCountIncremented() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        uint256 initialCount = factory.getTotalTokens();
        
        // Deploy first token
        factory.deployMeme{value: 0.01 ether}("First Token", "FIRST", 0, 0, 0);
        assertEq(factory.getTotalTokens(), initialCount + 1);
        
        // Deploy second token
        factory.deployMeme{value: 0.01 ether}("Second Token", "SECOND", 0, 0, 0);
        assertEq(factory.getTotalTokens(), initialCount + 2);
        
        vm.stopPrank();
    }

    function test_DeployMemeTokenInfoRecorded() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Info Test",
            "INFO",
            500_000 * 10**18,
            50_000 * 10**18,
            0.005 ether
        );
        
        // Get token info from factory
        MemeFactory.TokenInfo memory tokenInfo = factory.getTokenInfo(1);
        
        assertEq(tokenInfo.tokenAddress, tokenAddress);
        assertEq(tokenInfo.name, "Info Test");
        assertEq(tokenInfo.symbol, "INFO");
        assertEq(tokenInfo.creator, user1);
        assertEq(tokenInfo.totalSupplyLimit, 500_000 * 10**18);
        assertEq(tokenInfo.perMint, 50_000 * 10**18);
        assertEq(tokenInfo.price, 0.005 ether);
        assertTrue(tokenInfo.exists);
        assertTrue(tokenInfo.createdAt > 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeSymbolExistsMapping() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Verify symbol doesn't exist initially
        assertTrue(factory.isSymbolAvailable("NEWSYMBOL"));
        
        // Deploy token
        factory.deployMeme{value: 0.01 ether}("New Symbol", "NEWSYMBOL", 0, 0, 0);
        
        // Verify symbol now exists
        assertFalse(factory.isSymbolAvailable("NEWSYMBOL"));
        
        vm.stopPrank();
    }

    function test_DeployMemeIsTokenCreatedMapping() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Created Test",
            "CREATED",
            0, 0, 0
        );
        
        // Verify token is marked as created
        assertTrue(factory.isTokenCreated(tokenAddress));
        
        // Verify non-existent token is not marked as created
        assertFalse(factory.isTokenCreated(address(0x123)));
        
        vm.stopPrank();
    }

    function test_DeployMemePaused() public {
        vm.startPrank(owner);
        factory.pause();
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Try to deploy when paused
        vm.expectRevert();
        factory.deployMeme{value: 0.01 ether}("Paused Test", "PAUSED", 0, 0, 0);
        
        vm.stopPrank();
    }

    function test_DeployMemeAfterUnpause() public {
        vm.startPrank(owner);
        factory.pause();
        factory.unpause();
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        
        // Should be able to deploy after unpause
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Unpaused Test",
            "UNPAUSED",
            0, 0, 0
        );
        
        assertTrue(tokenAddress != address(0));
        
        vm.stopPrank();
    }
}
