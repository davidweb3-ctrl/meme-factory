// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MemeFactory} from "../src/MemeFactory.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {IMemeToken} from "../src/IMemeToken.sol";

contract CoreFunctionalityTest is Test {
    MemeFactory public factory;
    
    // Different roles for testing
    address public deployer;  // Factory deployer/owner
    address public issuer;    // Token issuer/creator
    address public buyer;     // Token buyer/minter
    address public project;   // Project team (receives 1% fee)
    
    // Test parameters
    string public constant TOKEN_NAME = "Test Meme Token";
    string public constant TOKEN_SYMBOL = "TMT";
    uint256 public constant TOTAL_SUPPLY_LIMIT = 1_000_000 * 10**18; // 1M tokens
    uint256 public constant PER_MINT = 1000; // 1000 tokens per mint (no decimals)
    uint256 public constant TOKEN_PRICE = 1 wei; // 1 wei per token (very small price)
    uint256 public constant CREATION_FEE = 0.01 ether; // 0.01 ETH creation fee

    function setUp() public {
        // Initialize different roles with valid addresses
        deployer = address(0x123);
        issuer = address(0x456);
        buyer = address(0x789);
        project = address(0xABC);
        
        // Deploy factory as deployer
        vm.startPrank(deployer);
        factory = new MemeFactory(deployer);
        vm.stopPrank();
        
        // Give initial ETH to roles
        vm.deal(issuer, 10 ether);
        vm.deal(buyer, 10 ether);
        vm.deal(project, 10 ether);
    }

    // ============ Test 1: Meme Deployment ============
    
    function test_MemeDeployment() public {
        console.log("=== Test 1: Meme Deployment ===");
        
        vm.startPrank(issuer);
        
        // Record initial state
        uint256 initialTokenCount = factory.getTotalTokens();
        uint256 initialIssuerBalance = issuer.balance;
        
        console.log("Initial token count:", initialTokenCount);
        console.log("Initial issuer balance:", initialIssuerBalance);
        
        // Deploy meme token
        address tokenAddress = factory.deployMeme{value: CREATION_FEE}(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOTAL_SUPPLY_LIMIT,
            PER_MINT,
            TOKEN_PRICE
        );
        
        vm.stopPrank();
        
        // Verify deployment
        assertTrue(tokenAddress != address(0), "Token address should not be zero");
        assertEq(factory.getTotalTokens(), initialTokenCount + 1, "Token count should increase");
        
        // Verify token properties
        IMemeToken token = IMemeToken(tokenAddress);
        assertEq(token.name(), TOKEN_NAME, "Token name should match");
        assertEq(token.symbol(), TOKEN_SYMBOL, "Token symbol should match");
        assertEq(token.owner(), issuer, "Token owner should be issuer");
        assertEq(token.issuer(), issuer, "Token issuer should be issuer");
        assertEq(token.totalSupplyLimit(), TOTAL_SUPPLY_LIMIT, "Total supply limit should match");
        assertEq(token.perMint(), PER_MINT, "Per mint should match");
        assertEq(token.price(), TOKEN_PRICE, "Token price should match");
        assertEq(token.minted(), 0, "Initial minted should be 0");
        assertEq(token.totalSupply(), 0, "Initial total supply should be 0");
        
        // Verify factory tracking
        assertTrue(factory.isTokenCreated(tokenAddress), "Token should be tracked by factory");
        assertFalse(factory.isSymbolAvailable(TOKEN_SYMBOL), "Symbol should not be available");
        
        // Verify fee deduction
        uint256 finalIssuerBalance = issuer.balance;
        assertEq(finalIssuerBalance, initialIssuerBalance - CREATION_FEE, "Creation fee should be deducted");
        
        console.log("Token deployed at:", tokenAddress);
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Total supply limit:", token.totalSupplyLimit());
        console.log("Per mint:", token.perMint());
        console.log("Token price:", token.price());
        console.log("Final issuer balance:", finalIssuerBalance);
        
        console.log("Meme deployment test passed!");
    }

    // ============ Test 2: Single Mint Success ============
    
    function test_SingleMintSuccess() public {
        console.log("=== Test 2: Single Mint Success ===");
        
        // First deploy a token
        vm.startPrank(issuer);
        address tokenAddress = factory.deployMeme{value: CREATION_FEE}(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOTAL_SUPPLY_LIMIT,
            PER_MINT,
            TOKEN_PRICE
        );
        vm.stopPrank();
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Record initial state
        uint256 initialBuyerBalance = buyer.balance;
        uint256 initialTokenBalance = token.balanceOf(buyer);
        uint256 initialMinted = token.minted();
        uint256 initialTotalSupply = token.totalSupply();
        
        console.log("Initial buyer ETH balance:", initialBuyerBalance);
        console.log("Initial token balance:", initialTokenBalance);
        console.log("Initial minted:", initialMinted);
        console.log("Initial total supply:", initialTotalSupply);
        
        // Calculate required payment
        uint256 requiredPayment = PER_MINT * TOKEN_PRICE;
        console.log("Required payment:", requiredPayment);
        
        // Mint tokens
        vm.startPrank(buyer);
        factory.mintMeme{value: requiredPayment}(tokenAddress, PER_MINT);
        vm.stopPrank();
        
        // Verify minting results
        uint256 finalBuyerBalance = buyer.balance;
        uint256 finalTokenBalance = token.balanceOf(buyer);
        uint256 finalMinted = token.minted();
        uint256 finalTotalSupply = token.totalSupply();
        
        assertEq(finalTokenBalance, initialTokenBalance + PER_MINT, "Token balance should increase");
        assertEq(finalMinted, initialMinted + PER_MINT, "Minted amount should increase");
        assertEq(finalTotalSupply, initialTotalSupply + PER_MINT, "Total supply should increase");
        assertEq(finalBuyerBalance, initialBuyerBalance - requiredPayment, "ETH balance should decrease");
        
        console.log("Final buyer ETH balance:", finalBuyerBalance);
        console.log("Final token balance:", finalTokenBalance);
        console.log("Final minted:", finalMinted);
        console.log("Final total supply:", finalTotalSupply);
        console.log("Payment made:", requiredPayment);
        
        console.log("Single mint success test passed!");
    }

    // ============ Test 3: Fee Distribution Correctness ============
    
    function test_FeeDistributionCorrectness() public {
        console.log("=== Test 3: Fee Distribution Correctness ===");
        
        // First deploy a token
        vm.startPrank(issuer);
        address tokenAddress = factory.deployMeme{value: CREATION_FEE}(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOTAL_SUPPLY_LIMIT,
            PER_MINT,
            TOKEN_PRICE
        );
        vm.stopPrank();
        
        // Record initial balances
        uint256 initialDeployerBalance = deployer.balance; // Project receives 1%
        uint256 initialIssuerBalance = issuer.balance;     // Issuer receives 99%
        uint256 initialBuyerBalance = buyer.balance;
        
        console.log("Initial deployer balance:", initialDeployerBalance);
        console.log("Initial issuer balance:", initialIssuerBalance);
        console.log("Initial buyer balance:", initialBuyerBalance);
        
        // Calculate payment and expected fee distribution
        uint256 payment = PER_MINT * TOKEN_PRICE;
        uint256 expectedProjectFee = payment / 100; // 1%
        uint256 expectedIssuerFee = payment - expectedProjectFee; // 99%
        
        console.log("Total payment:", payment);
        console.log("Expected project fee (1%):", expectedProjectFee);
        console.log("Expected issuer fee (99%):", expectedIssuerFee);
        
        // Mint tokens
        vm.startPrank(buyer);
        factory.mintMeme{value: payment}(tokenAddress, PER_MINT);
        vm.stopPrank();
        
        // Verify fee distribution
        uint256 finalDeployerBalance = deployer.balance;
        uint256 finalIssuerBalance = issuer.balance;
        uint256 finalBuyerBalance = buyer.balance;
        
        assertEq(finalDeployerBalance, initialDeployerBalance + expectedProjectFee, 
                "Project should receive 1% fee");
        assertEq(finalIssuerBalance, initialIssuerBalance + expectedIssuerFee, 
                "Issuer should receive 99% fee");
        assertEq(finalBuyerBalance, initialBuyerBalance - payment, 
                "Buyer should pay the full amount");
        
        // Verify total distribution equals payment
        uint256 totalDistributed = (finalDeployerBalance - initialDeployerBalance) + 
                                  (finalIssuerBalance - initialIssuerBalance);
        assertEq(totalDistributed, payment, "Total distribution should equal payment");
        
        console.log("Final deployer balance:", finalDeployerBalance);
        console.log("Final issuer balance:", finalIssuerBalance);
        console.log("Final buyer balance:", finalBuyerBalance);
        console.log("Actual project fee received:", finalDeployerBalance - initialDeployerBalance);
        console.log("Actual issuer fee received:", finalIssuerBalance - initialIssuerBalance);
        console.log("Total distributed:", totalDistributed);
        
        console.log("Fee distribution correctness test passed!");
    }

    // ============ Test 4: Overflow Mint Revert ============
    
    function test_OverflowMintRevert() public {
        console.log("=== Test 4: Overflow Mint Revert ===");
        
        // Deploy token with low supply limit
        uint256 lowSupplyLimit = PER_MINT; // Set limit equal to perMint
        vm.startPrank(issuer);
        address tokenAddress = factory.deployMeme{value: CREATION_FEE}(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            lowSupplyLimit,
            PER_MINT,
            TOKEN_PRICE
        );
        vm.stopPrank();
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        console.log("Token supply limit:", token.totalSupplyLimit());
        console.log("Per mint amount:", token.perMint());
        
        // First mint should succeed
        uint256 payment = PER_MINT * TOKEN_PRICE;
        vm.startPrank(buyer);
        factory.mintMeme{value: payment}(tokenAddress, PER_MINT);
        vm.stopPrank();
        
        // Verify first mint succeeded
        assertEq(token.minted(), PER_MINT, "First mint should succeed");
        assertEq(token.totalSupply(), PER_MINT, "Total supply should equal perMint");
        assertEq(token.balanceOf(buyer), PER_MINT, "Buyer should have tokens");
        
        console.log("After first mint:");
        console.log("Minted:", token.minted());
        console.log("Total supply:", token.totalSupply());
        console.log("Buyer balance:", token.balanceOf(buyer));
        
        // Second mint should fail (exceeds supply limit)
        vm.startPrank(buyer);
        vm.expectRevert("Exceeds total supply limit");
        factory.mintMeme{value: payment}(tokenAddress, PER_MINT);
        vm.stopPrank();
        
        // Verify state unchanged after failed mint
        assertEq(token.minted(), PER_MINT, "Minted should not change after failed mint");
        assertEq(token.totalSupply(), PER_MINT, "Total supply should not change after failed mint");
        assertEq(token.balanceOf(buyer), PER_MINT, "Buyer balance should not change after failed mint");
        
        console.log("After failed second mint:");
        console.log("Minted:", token.minted());
        console.log("Total supply:", token.totalSupply());
        console.log("Buyer balance:", token.balanceOf(buyer));
        
        console.log("Overflow mint revert test passed!");
    }

    // ============ Comprehensive Integration Test ============
    
    function test_CompleteWorkflow() public {
        console.log("=== Complete Workflow Integration Test ===");
        
        // Step 1: Deploy token
        vm.startPrank(issuer);
        address tokenAddress = factory.deployMeme{value: CREATION_FEE}(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOTAL_SUPPLY_LIMIT,
            PER_MINT,
            TOKEN_PRICE
        );
        vm.stopPrank();
        
        IMemeToken token = IMemeToken(tokenAddress);
        console.log("Step 1 - Token deployed:", tokenAddress);
        
        // Step 2: Multiple successful mints
        uint256 payment = PER_MINT * TOKEN_PRICE;
        uint256 totalMinted = 0;
        
        for (uint256 i = 0; i < 3; i++) {
            vm.startPrank(buyer);
            factory.mintMeme{value: payment}(tokenAddress, PER_MINT);
            vm.stopPrank();
            
            totalMinted += PER_MINT;
            assertEq(token.minted(), totalMinted, "Minted amount should accumulate");
            assertEq(token.totalSupply(), totalMinted, "Total supply should match minted");
            assertEq(token.balanceOf(buyer), totalMinted, "Buyer balance should accumulate");
            
            console.log("Step 2 - Mint", i + 1, "completed. Total minted:", totalMinted);
        }
        
        // Step 3: Verify final state
        assertEq(token.minted(), 3 * PER_MINT, "Final minted should be 3x perMint");
        assertEq(token.totalSupply(), 3 * PER_MINT, "Final total supply should be 3x perMint");
        assertEq(token.balanceOf(buyer), 3 * PER_MINT, "Final buyer balance should be 3x perMint");
        
        console.log("Step 3 - Final verification completed");
        console.log("Total tokens minted:", token.minted());
        console.log("Total supply:", token.totalSupply());
        console.log("Buyer token balance:", token.balanceOf(buyer));
        
        console.log("Complete workflow integration test passed!");
    }

    // ============ Edge Case Tests ============
    
    function test_DefaultParameters() public {
        console.log("=== Test: Default Parameters ===");
        
        vm.startPrank(issuer);
        address tokenAddress = factory.deployMeme{value: CREATION_FEE}(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            0, // Use default totalSupplyLimit
            0, // Use default perMint
            0  // Use default price
        );
        vm.stopPrank();
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Get default parameters from factory
        (uint256 defaultTotalSupplyLimit, uint256 defaultPerMint, uint256 defaultPrice) = 
            factory.getDefaultParameters();
        
        assertEq(token.totalSupplyLimit(), defaultTotalSupplyLimit, "Should use default totalSupplyLimit");
        assertEq(token.perMint(), defaultPerMint, "Should use default perMint");
        assertEq(token.price(), defaultPrice, "Should use default price");
        
        console.log("Default totalSupplyLimit:", defaultTotalSupplyLimit);
        console.log("Default perMint:", defaultPerMint);
        console.log("Default price:", defaultPrice);
        
        console.log("Default parameters test passed!");
    }

    function test_CustomMintAmount() public {
        console.log("=== Test: Custom Mint Amount ===");
        
        vm.startPrank(issuer);
        address tokenAddress = factory.deployMeme{value: CREATION_FEE}(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOTAL_SUPPLY_LIMIT,
            PER_MINT,
            TOKEN_PRICE
        );
        vm.stopPrank();
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Mint custom amount (different from perMint)
        uint256 customAmount = PER_MINT / 2; // Half of perMint
        uint256 customPayment = customAmount * TOKEN_PRICE;
        
        vm.startPrank(buyer);
        factory.mintMeme{value: customPayment}(tokenAddress, customAmount);
        vm.stopPrank();
        
        assertEq(token.minted(), customAmount, "Minted should equal custom amount");
        assertEq(token.totalSupply(), customAmount, "Total supply should equal custom amount");
        assertEq(token.balanceOf(buyer), customAmount, "Buyer balance should equal custom amount");
        
        console.log("Custom mint amount:", customAmount);
        console.log("Custom payment:", customPayment);
        console.log("Final minted:", token.minted());
        
        console.log("Custom mint amount test passed!");
    }
}
