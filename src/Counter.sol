// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MemeToken
 * @dev ERC20 Token implementation for Meme Factory
 * @notice This contract serves as the implementation for all meme tokens created by the factory
 */
contract MemeToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    
    bool public burnEnabled = true;
    uint256 public burnRate = 100; // 1% burn rate (100 basis points)
    
    event TokensBurned(address indexed from, uint256 amount);
    event BurnRateUpdated(uint256 newBurnRate);
    event BurnToggled(bool enabled);

    /**
     * @dev Constructor that initializes the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param initialOwner The initial owner of the token
     */
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        _mint(initialOwner, INITIAL_SUPPLY);
    }

    /**
     * @dev Override transfer to include burn mechanism
     * @param to The recipient address
     * @param amount The amount to transfer
     * @return bool Success status
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 burnAmount = 0;
        
        if (burnEnabled && burnRate > 0) {
            burnAmount = (amount * burnRate) / 10000; // Calculate burn amount
            if (burnAmount > 0) {
                _burn(msg.sender, burnAmount);
                emit TokensBurned(msg.sender, burnAmount);
            }
        }
        
        uint256 transferAmount = amount - burnAmount;
        return super.transfer(to, transferAmount);
    }

    /**
     * @dev Override transferFrom to include burn mechanism
     * @param from The sender address
     * @param to The recipient address
     * @param amount The amount to transfer
     * @return bool Success status
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 burnAmount = 0;
        
        if (burnEnabled && burnRate > 0) {
            burnAmount = (amount * burnRate) / 10000; // Calculate burn amount
            if (burnAmount > 0) {
                _burn(from, burnAmount);
                emit TokensBurned(from, burnAmount);
            }
        }
        
        uint256 transferAmount = amount - burnAmount;
        return super.transferFrom(from, to, transferAmount);
    }

    /**
     * @dev Set the burn rate (only owner)
     * @param newBurnRate The new burn rate in basis points (100 = 1%)
     */
    function setBurnRate(uint256 newBurnRate) external onlyOwner {
        require(newBurnRate <= 1000, "Burn rate cannot exceed 10%");
        burnRate = newBurnRate;
        emit BurnRateUpdated(newBurnRate);
    }

    /**
     * @dev Toggle burn functionality (only owner)
     * @param enabled Whether burn should be enabled
     */
    function toggleBurn(bool enabled) external onlyOwner {
        burnEnabled = enabled;
        emit BurnToggled(enabled);
    }

    /**
     * @dev Manual burn function (only owner)
     * @param amount The amount to burn
     */
    function manualBurn(uint256 amount) external onlyOwner nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Mint additional tokens (only owner)
     * @param to The recipient address
     * @param amount The amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }
}
