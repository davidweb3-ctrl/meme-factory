// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title MemeToken
 * @dev ERC20 Token implementation for Meme Factory using upgradeable pattern
 * @notice This contract serves as the implementation for all meme tokens created by the factory
 */
contract MemeToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // Token configuration
    uint256 public totalSupplyLimit;  // Maximum total supply
    uint256 public perMint;           // Amount to mint per mintByFactory call
    uint256 public price;             // Price per token in wei
    address public issuer;            // Token issuer/creator
    uint256 public minted;            // Total amount minted so far
    
    // Burn mechanism
    bool public burnEnabled;
    uint256 public burnRate; // 1% burn rate (100 basis points)
    
    // Factory address - only factory can call mintByFactory
    address public factory;
    
    // Events
    event TokensBurned(address indexed from, uint256 amount);
    event BurnRateUpdated(uint256 newBurnRate);
    event BurnToggled(bool enabled);
    event TokensMinted(address indexed to, uint256 amount);
    event PriceUpdated(uint256 newPrice);
    event PerMintUpdated(uint256 newPerMint);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize function for proxy contracts
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param initialOwner The initial owner of the token
     * @param factory_ The factory contract address
     * @param totalSupplyLimit_ Maximum total supply
     * @param perMint_ Amount to mint per mintByFactory call
     * @param price_ Price per token in wei
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address initialOwner,
        address factory_,
        uint256 totalSupplyLimit_,
        uint256 perMint_,
        uint256 price_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
        
        require(factory_ != address(0), "Factory cannot be zero address");
        require(totalSupplyLimit_ > 0, "Total supply limit must be greater than 0");
        require(perMint_ > 0, "Per mint must be greater than 0");
        
        factory = factory_;
        totalSupplyLimit = totalSupplyLimit_;
        perMint = perMint_;
        price = price_;
        issuer = initialOwner;
        minted = 0;
        
        // Default burn settings
        burnEnabled = true;
        burnRate = 100; // 1%
    }

    /**
     * @dev Mint tokens by factory (only factory can call)
     * @param to The recipient address
     * @param amount The amount to mint
     */
    function mintByFactory(address to, uint256 amount) external {
        require(msg.sender == factory, "Only factory can call this function");
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(minted + amount <= totalSupplyLimit, "Exceeds total supply limit");
        
        minted += amount;
        _mint(to, amount);
        
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Mint tokens by factory with default perMint amount
     * @param to The recipient address
     */
    function mintByFactory(address to) external {
        require(msg.sender == factory, "Only factory can call this function");
        require(to != address(0), "Cannot mint to zero address");
        require(perMint > 0, "Per mint must be greater than 0");
        require(minted + perMint <= totalSupplyLimit, "Exceeds total supply limit");
        
        minted += perMint;
        _mint(to, perMint);
        
        emit TokensMinted(to, perMint);
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
     * @dev Set the price per token (only owner)
     * @param newPrice The new price in wei
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    /**
     * @dev Set the per mint amount (only owner)
     * @param newPerMint The new per mint amount
     */
    function setPerMint(uint256 newPerMint) external onlyOwner {
        require(newPerMint > 0, "Per mint must be greater than 0");
        perMint = newPerMint;
        emit PerMintUpdated(newPerMint);
    }

    /**
     * @dev Get token information
     * @return name_ Token name
     * @return symbol_ Token symbol
     * @return totalSupply_ Current total supply
     * @return totalSupplyLimit_ Maximum total supply
     * @return perMint_ Amount per mint
     * @return price_ Price per token
     * @return issuer_ Token issuer
     * @return minted_ Total minted amount
     */
    function getTokenInfo() external view returns (
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 totalSupplyLimit_,
        uint256 perMint_,
        uint256 price_,
        address issuer_,
        uint256 minted_
    ) {
        return (
            name(),
            symbol(),
            totalSupply(),
            totalSupplyLimit,
            perMint,
            price,
            issuer,
            minted
        );
    }

    /**
     * @dev Check if more tokens can be minted
     * @return bool True if more tokens can be minted
     */
    function canMint() external view returns (bool) {
        return minted < totalSupplyLimit;
    }

    /**
     * @dev Get remaining mintable amount
     * @return uint256 Remaining amount that can be minted
     */
    function getRemainingMintable() external view returns (uint256) {
        return totalSupplyLimit - minted;
    }
}