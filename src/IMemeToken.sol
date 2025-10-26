// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMemeToken
 * @dev Interface for Meme Token contracts
 * @notice This interface defines the standard functions that Meme Token contracts should implement
 */
interface IMemeToken {
    // ============ Events ============
    
    /**
     * @dev Emitted when tokens are minted by the factory
     * @param to The recipient address
     * @param amount The amount of tokens minted
     */
    event TokensMinted(address indexed to, uint256 amount);
    
    /**
     * @dev Emitted when tokens are burned
     * @param from The address tokens were burned from
     * @param amount The amount of tokens burned
     */
    event TokensBurned(address indexed from, uint256 amount);
    
    /**
     * @dev Emitted when burn rate is updated
     * @param newBurnRate The new burn rate in basis points
     */
    event BurnRateUpdated(uint256 newBurnRate);
    
    /**
     * @dev Emitted when burn functionality is toggled
     * @param enabled Whether burn is enabled
     */
    event BurnToggled(bool enabled);
    
    /**
     * @dev Emitted when price is updated
     * @param newPrice The new price per token
     */
    event PriceUpdated(uint256 newPrice);
    
    /**
     * @dev Emitted when per mint amount is updated
     * @param newPerMint The new per mint amount
     */
    event PerMintUpdated(uint256 newPerMint);

    // ============ ERC20 Standard Functions ============
    
    /**
     * @dev Returns the name of the token
     * @return The token name
     */
    function name() external view returns (string memory);
    
    /**
     * @dev Returns the symbol of the token
     * @return The token symbol
     */
    function symbol() external view returns (string memory);
    
    /**
     * @dev Returns the decimals of the token
     * @return The token decimals
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev Returns the total supply of the token
     * @return The total supply
     */
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Returns the balance of the specified address
     * @param account The address to query the balance of
     * @return The balance of the specified address
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Transfers tokens to a specified address
     * @param to The address to transfer to
     * @param amount The amount to transfer
     * @return A boolean indicating whether the transfer was successful
     */
    function transfer(address to, uint256 amount) external returns (bool);
    
    /**
     * @dev Transfers tokens from one address to another
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param amount The amount to transfer
     * @return A boolean indicating whether the transfer was successful
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    /**
     * @dev Approves the spender to spend the specified amount
     * @param spender The address to approve
     * @param amount The amount to approve
     * @return A boolean indicating whether the approval was successful
     */
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
     * @dev Returns the allowance of the spender for the owner
     * @param owner The address of the owner
     * @param spender The address of the spender
     * @return The allowance amount
     */
    function allowance(address owner, address spender) external view returns (uint256);

    // ============ Meme Token Specific Functions ============
    
    /**
     * @dev Returns the maximum total supply limit
     * @return The total supply limit
     */
    function totalSupplyLimit() external view returns (uint256);
    
    /**
     * @dev Returns the amount minted per factory call
     * @return The per mint amount
     */
    function perMint() external view returns (uint256);
    
    /**
     * @dev Returns the price per token in wei
     * @return The token price
     */
    function price() external view returns (uint256);
    
    /**
     * @dev Returns the token issuer/creator address
     * @return The issuer address
     */
    function issuer() external view returns (address);
    
    /**
     * @dev Returns the total amount minted so far
     * @return The minted amount
     */
    function minted() external view returns (uint256);
    
    /**
     * @dev Returns whether burn functionality is enabled
     * @return True if burn is enabled
     */
    function burnEnabled() external view returns (bool);
    
    /**
     * @dev Returns the burn rate in basis points
     * @return The burn rate
     */
    function burnRate() external view returns (uint256);
    
    /**
     * @dev Returns the factory contract address
     * @return The factory address
     */
    function factory() external view returns (address);
    
    /**
     * @dev Returns the owner of the token contract
     * @return The owner address
     */
    function owner() external view returns (address);

    // ============ Factory Functions ============
    
    /**
     * @dev Mints tokens to a specified address (only factory can call)
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mintByFactory(address to, uint256 amount) external;
    
    /**
     * @dev Mints tokens to a specified address using default perMint amount (only factory can call)
     * @param to The address to mint tokens to
     */
    function mintByFactory(address to) external;

    // ============ Owner Functions ============
    
    /**
     * @dev Sets the burn rate (only owner can call)
     * @param newBurnRate The new burn rate in basis points
     */
    function setBurnRate(uint256 newBurnRate) external;
    
    /**
     * @dev Toggles burn functionality (only owner can call)
     * @param enabled Whether to enable burn
     */
    function toggleBurn(bool enabled) external;
    
    /**
     * @dev Manually burns tokens (only owner can call)
     * @param amount The amount of tokens to burn
     */
    function manualBurn(uint256 amount) external;
    
    /**
     * @dev Sets the price per token (only owner can call)
     * @param newPrice The new price in wei
     */
    function setPrice(uint256 newPrice) external;
    
    /**
     * @dev Sets the per mint amount (only owner can call)
     * @param newPerMint The new per mint amount
     */
    function setPerMint(uint256 newPerMint) external;

    // ============ Utility Functions ============
    
    /**
     * @dev Returns comprehensive token information
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
    );
    
    /**
     * @dev Checks if more tokens can be minted
     * @return True if more tokens can be minted
     */
    function canMint() external view returns (bool);
    
    /**
     * @dev Returns the remaining mintable amount
     * @return The remaining amount that can be minted
     */
    function getRemainingMintable() external view returns (uint256);
}
