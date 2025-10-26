// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MemeToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title MemeFactory
 * @dev Factory contract for creating Meme Tokens using EIP-1167 minimal proxies
 * @notice This contract deploys a single MemeToken implementation and creates proxies for each new token
 */
contract MemeFactory is Ownable, ReentrancyGuard, Pausable {
    // EIP-1167 minimal proxy bytecode
    bytes private constant PROXY_BYTECODE = hex"3d602d80600a3d3981f3363d3d373d3d3d363d7300000000000000000000000000000000000000005af43d82803e903d91602b57fd5bf3";
    
    address public immutable implementation;
    uint256 public tokenCount;
    uint256 public creationFee = 0.01 ether; // Default creation fee
    
    // Default token parameters
    uint256 public defaultTotalSupplyLimit = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public defaultPerMint = 100_000_000 * 10**18; // 100 million tokens per mint
    uint256 public defaultPrice = 0.001 ether; // 0.001 ETH per token
    
    struct TokenInfo {
        address tokenAddress;
        string name;
        string symbol;
        address creator;
        uint256 createdAt;
        uint256 totalSupplyLimit;
        uint256 perMint;
        uint256 price;
        bool exists;
    }
    
    mapping(uint256 => TokenInfo) public tokens;
    mapping(address => bool) public isTokenCreated;
    mapping(string => bool) public symbolExists;
    
    event TokenCreated(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        string name,
        string symbol,
        address indexed creator,
        uint256 totalSupplyLimit,
        uint256 perMint,
        uint256 price
    );
    event CreationFeeUpdated(uint256 newFee);
    event DefaultParametersUpdated(uint256 totalSupplyLimit, uint256 perMint, uint256 price);
    event FactoryPaused();
    event FactoryUnpaused();

    /**
     * @dev Constructor that deploys the MemeToken implementation
     * @param initialOwner The initial owner of the factory
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        // Deploy the implementation contract
        implementation = address(new MemeToken());
    }

    /**
     * @dev Create a new Meme Token using minimal proxy
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param totalSupplyLimit_ Maximum total supply (0 to use default)
     * @param perMint_ Amount per mint (0 to use default)
     * @param price_ Price per token (0 to use default)
     * @return tokenAddress The address of the created token proxy
     */
    function createToken(
        string memory name,
        string memory symbol,
        uint256 totalSupplyLimit_,
        uint256 perMint_,
        uint256 price_
    ) external payable whenNotPaused nonReentrant returns (address tokenAddress) {
        require(msg.value >= creationFee, "Insufficient creation fee");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(!symbolExists[symbol], "Symbol already exists");
        require(bytes(name).length <= 50, "Name too long");
        require(bytes(symbol).length <= 10, "Symbol too long");

        // Use default values if 0 is provided
        uint256 finalTotalSupplyLimit = totalSupplyLimit_ == 0 ? defaultTotalSupplyLimit : totalSupplyLimit_;
        uint256 finalPerMint = perMint_ == 0 ? defaultPerMint : perMint_;
        uint256 finalPrice = price_ == 0 ? defaultPrice : price_;

        // Create minimal proxy
        bytes memory bytecode = abi.encodePacked(
            PROXY_BYTECODE,
            abi.encode(implementation)
        );
        
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, msg.sender, block.timestamp));
        assembly {
            tokenAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        require(tokenAddress != address(0), "Failed to create proxy");
        
        // Initialize the proxy with token parameters
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature(
                "initialize(string,string,address,address,uint256,uint256,uint256)",
                name,
                symbol,
                msg.sender,
                address(this),
                finalTotalSupplyLimit,
                finalPerMint,
                finalPrice
            )
        );
        require(success, "Failed to initialize token");

        // Record token information
        tokenCount++;
        tokens[tokenCount] = TokenInfo({
            tokenAddress: tokenAddress,
            name: name,
            symbol: symbol,
            creator: msg.sender,
            createdAt: block.timestamp,
            totalSupplyLimit: finalTotalSupplyLimit,
            perMint: finalPerMint,
            price: finalPrice,
            exists: true
        });
        
        isTokenCreated[tokenAddress] = true;
        symbolExists[symbol] = true;

        emit TokenCreated(
            tokenCount, 
            tokenAddress, 
            name, 
            symbol, 
            msg.sender,
            finalTotalSupplyLimit,
            finalPerMint,
            finalPrice
        );

        // Refund excess payment
        if (msg.value > creationFee) {
            payable(msg.sender).transfer(msg.value - creationFee);
        }
    }

    /**
     * @dev Create a new Meme Token with default parameters
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @return tokenAddress The address of the created token proxy
     */
    function createTokenWithDefaults(
        string memory name,
        string memory symbol
    ) external payable whenNotPaused nonReentrant returns (address tokenAddress) {
        require(msg.value >= creationFee, "Insufficient creation fee");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(!symbolExists[symbol], "Symbol already exists");
        require(bytes(name).length <= 50, "Name too long");
        require(bytes(symbol).length <= 10, "Symbol too long");

        // Use default values
        uint256 finalTotalSupplyLimit = defaultTotalSupplyLimit;
        uint256 finalPerMint = defaultPerMint;
        uint256 finalPrice = defaultPrice;

        // Create minimal proxy
        bytes memory bytecode = abi.encodePacked(
            PROXY_BYTECODE,
            abi.encode(implementation)
        );
        
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, msg.sender, block.timestamp));
        assembly {
            tokenAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        require(tokenAddress != address(0), "Failed to create proxy");
        
        // Initialize the proxy with token parameters
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature(
                "initialize(string,string,address,address,uint256,uint256,uint256)",
                name,
                symbol,
                msg.sender,
                address(this),
                finalTotalSupplyLimit,
                finalPerMint,
                finalPrice
            )
        );
        require(success, "Failed to initialize token");

        // Record token information
        tokenCount++;
        tokens[tokenCount] = TokenInfo({
            tokenAddress: tokenAddress,
            name: name,
            symbol: symbol,
            creator: msg.sender,
            createdAt: block.timestamp,
            totalSupplyLimit: finalTotalSupplyLimit,
            perMint: finalPerMint,
            price: finalPrice,
            exists: true
        });
        
        isTokenCreated[tokenAddress] = true;
        symbolExists[symbol] = true;

        emit TokenCreated(
            tokenCount, 
            tokenAddress, 
            name, 
            symbol, 
            msg.sender,
            finalTotalSupplyLimit,
            finalPerMint,
            finalPrice
        );

        // Refund excess payment
        if (msg.value > creationFee) {
            payable(msg.sender).transfer(msg.value - creationFee);
        }
    }

    /**
     * @dev Mint tokens for a specific token (only factory can call)
     * @param tokenAddress The token contract address
     * @param to The recipient address
     * @param amount The amount to mint (0 to use default perMint)
     */
    function mintToken(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(isTokenCreated[tokenAddress], "Token not created by this factory");
        
        if (amount == 0) {
            // Use default perMint amount
            (bool success, ) = tokenAddress.call(
                abi.encodeWithSignature("mintByFactory(address)", to)
            );
            require(success, "Failed to mint tokens");
        } else {
            // Use specified amount
            (bool success, ) = tokenAddress.call(
                abi.encodeWithSignature("mintByFactory(address,uint256)", to, amount)
            );
            require(success, "Failed to mint tokens");
        }
    }

    /**
     * @dev Get token information by ID
     * @param tokenId The token ID
     * @return TokenInfo struct containing token details
     */
    function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory) {
        require(tokens[tokenId].exists, "Token does not exist");
        return tokens[tokenId];
    }

    /**
     * @dev Get all tokens created by a specific address
     * @param creator The creator's address
     * @return tokenIds Array of token IDs created by the address
     */
    function getTokensByCreator(address creator) external view returns (uint256[] memory) {
        uint256[] memory creatorTokens = new uint256[](tokenCount);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= tokenCount; i++) {
            if (tokens[i].creator == creator) {
                creatorTokens[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = creatorTokens[i];
        }
        
        return result;
    }

    /**
     * @dev Set the creation fee (only owner)
     * @param newFee The new creation fee in wei
     */
    function setCreationFee(uint256 newFee) external onlyOwner {
        creationFee = newFee;
        emit CreationFeeUpdated(newFee);
    }

    /**
     * @dev Set default token parameters (only owner)
     * @param totalSupplyLimit_ Default total supply limit
     * @param perMint_ Default per mint amount
     * @param price_ Default price per token
     */
    function setDefaultParameters(
        uint256 totalSupplyLimit_,
        uint256 perMint_,
        uint256 price_
    ) external onlyOwner {
        require(totalSupplyLimit_ > 0, "Total supply limit must be greater than 0");
        require(perMint_ > 0, "Per mint must be greater than 0");
        
        defaultTotalSupplyLimit = totalSupplyLimit_;
        defaultPerMint = perMint_;
        defaultPrice = price_;
        
        emit DefaultParametersUpdated(totalSupplyLimit_, perMint_, price_);
    }

    /**
     * @dev Pause the factory (only owner)
     */
    function pause() external onlyOwner {
        _pause();
        emit FactoryPaused();
    }

    /**
     * @dev Unpause the factory (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
        emit FactoryUnpaused();
    }

    /**
     * @dev Withdraw contract balance (only owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Get the total number of tokens created
     * @return The total token count
     */
    function getTotalTokens() external view returns (uint256) {
        return tokenCount;
    }

    /**
     * @dev Check if a symbol is available
     * @param symbol The symbol to check
     * @return True if symbol is available
     */
    function isSymbolAvailable(string memory symbol) external view returns (bool) {
        return !symbolExists[symbol];
    }

    /**
     * @dev Get default parameters
     * @return totalSupplyLimit_ Default total supply limit
     * @return perMint_ Default per mint amount
     * @return price_ Default price per token
     */
    function getDefaultParameters() external view returns (
        uint256 totalSupplyLimit_,
        uint256 perMint_,
        uint256 price_
    ) {
        return (defaultTotalSupplyLimit, defaultPerMint, defaultPrice);
    }
}