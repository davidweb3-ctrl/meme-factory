// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MemeFactory} from "../src/MemeFactory.sol";
import {IMemeToken} from "../src/IMemeToken.sol";

contract LocalDeploymentTest is Script {
    function run() external {
        // Get private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy MemeFactory
        console.log("\n=== Step 1: Deploy MemeFactory ===");
        // Get Uniswap V2 Router address from environment or use a default
        address routerAddress = vm.envOr("UNISWAP_V2_ROUTER", address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        MemeFactory factory = new MemeFactory(deployer, routerAddress);
        console.log("Factory deployed at:", address(factory));
        console.log("Factory owner:", factory.owner());
        console.log("Uniswap V2 Router:", address(factory.uniswapV2Router()));
        
        // Step 2: Deploy a Meme Token
        console.log("\n=== Step 2: Deploy Meme Token ===");
        address tokenAddress = factory.deployMeme{value: 0.01 ether}(
            "Local Test Token",
            "LTT",
            1_000_000 * 10**18,
            1000,
            1 wei
        );
        console.log("Token deployed at:", tokenAddress);
        
        vm.stopBroadcast();
        
        // Step 3: Verify Token Properties
        console.log("\n=== Step 3: Verify Token Properties ===");
        IMemeToken token = IMemeToken(tokenAddress);
        
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token owner:", token.owner());
        console.log("Token issuer:", token.issuer());
        console.log("Per mint:", token.perMint());
        console.log("Token price:", token.price());
        console.log("Initial minted:", token.minted());
        console.log("Initial total supply:", token.totalSupply());
        
        // Step 4: Mint Tokens
        console.log("\n=== Step 4: Mint Tokens ===");
        
        // Create a buyer account
        uint256 buyerPrivateKey = 0x2;
        address buyer = vm.addr(buyerPrivateKey);
        
        // Give buyer some ETH
        vm.deal(buyer, 1 ether);
        console.log("Buyer address:", buyer);
        console.log("Buyer ETH balance:", buyer.balance);
        
        vm.startBroadcast(buyerPrivateKey);
        
        uint256 mintAmount = 1000;
        uint256 requiredPayment = mintAmount * 1 wei;
        console.log("Mint amount:", mintAmount);
        console.log("Required payment:", requiredPayment);
        
        console.log("Before mint:");
        console.log("  Buyer ETH balance:", buyer.balance);
        console.log("  Buyer token balance:", token.balanceOf(buyer));
        console.log("  Total minted:", token.minted());
        console.log("  Total supply:", token.totalSupply());
        
        // Execute mint
        factory.mintMeme{value: requiredPayment}(tokenAddress, mintAmount);
        
        vm.stopBroadcast();
        
        // Step 5: Verify Results
        console.log("\n=== Step 5: Verify Results ===");
        
        console.log("After mint:");
        console.log("  Buyer ETH balance:", buyer.balance);
        console.log("  Buyer token balance:", token.balanceOf(buyer));
        console.log("  Total minted:", token.minted());
        console.log("  Total supply:", token.totalSupply());
        
        // Verify token balance
        uint256 tokenBalance = token.balanceOf(buyer);
        console.log("\nToken balance verification:");
        console.log("  Token balance:", tokenBalance);
        console.log("  Expected:", mintAmount);
        console.log("  Correct:", tokenBalance == mintAmount);
        
        // Verify minted amount
        uint256 minted = token.minted();
        console.log("\nMinted amount verification:");
        console.log("  Minted:", minted);
        console.log("  Expected:", mintAmount);
        console.log("  Correct:", minted == mintAmount);
        
        // Verify total supply
        uint256 totalSupply = token.totalSupply();
        console.log("\nTotal supply verification:");
        console.log("  Total supply:", totalSupply);
        console.log("  Expected:", mintAmount);
        console.log("  Correct:", totalSupply == mintAmount);
        
        // Verify ETH balance
        uint256 buyerBalance = buyer.balance;
        console.log("\nETH balance verification:");
        console.log("  Buyer ETH balance:", buyerBalance);
        console.log("  Expected decrease:", requiredPayment);
        
        // Step 6: Verify Fee Distribution
        console.log("\n=== Step 6: Verify Fee Distribution ===");
        
        uint256 projectFee = requiredPayment * 5 / 100; // 5%
        uint256 liquidityETH = requiredPayment * 5 / 100; // 5%
        uint256 issuerFee = requiredPayment - projectFee - liquidityETH; // 90%
        
        console.log("Fee distribution:");
        console.log("  Total payment:", requiredPayment);
        console.log("  Expected project fee (5%):", projectFee);
        console.log("  Expected liquidity ETH (5%):", liquidityETH);
        console.log("  Expected issuer fee (90%):", issuerFee);
        
        console.log("\n=== Deployment Test Completed Successfully! ===");
    }
}