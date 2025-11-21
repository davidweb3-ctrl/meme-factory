// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IMemeToken.sol";
import "./MemeToken.sol";
import "./IUniswapV2Router.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title MemeFactory
 * @dev Factory contract for creating Meme Tokens using EIP-1167 minimal proxies
 * @notice This contract deploys a single MemeToken implementation and creates proxies for each new token
 */
contract MemeFactory is Ownable, ReentrancyGuard, Pausable {
    address public immutable implementation;
    uint256 public tokenCount;
    uint256 public creationFee = 0.01 ether; // Default creation fee
    IUniswapV2Router public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factory;
    address public WETH;
    
    // Track liquidity pools for tokens
    mapping(address => address) public tokenPair; // token => pair address
    
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
    event MemeDeployed(
        address indexed tokenAddress,
        string name,
        string symbol,
        address indexed issuer,
        uint256 totalSupplyLimit,
        uint256 perMint,
        uint256 price
    );
    event MemeMinted(
        address indexed tokenAddress,
        address indexed minter,
        uint256 amount,
        uint256 totalCost,
        uint256 projectFee,
        uint256 issuerFee
    );
    event LiquidityAdded(
        address indexed tokenAddress,
        address indexed pair,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 liquidity
    );
    event MemeBought(
        address indexed tokenAddress,
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event CreationFeeUpdated(uint256 newFee);
    event DefaultParametersUpdated(uint256 totalSupplyLimit, uint256 perMint, uint256 price);
    event FactoryPaused();
    event FactoryUnpaused();

    /**
     * @dev Constructor that deploys the MemeToken implementation
     * @param initialOwner The initial owner of the factory
     * @param routerAddress The Uniswap V2 Router address
     */
    constructor(address initialOwner, address routerAddress) Ownable(initialOwner) {
        // Deploy the implementation contract
        implementation = address(new MemeToken());
        
        // Set Uniswap V2 Router
        require(routerAddress != address(0), "Router address cannot be zero");
        uniswapV2Router = IUniswapV2Router(routerAddress);
        WETH = uniswapV2Router.WETH();
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
    }

    /**
     * @dev Deploy a new Meme Token using OpenZeppelin Clones
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param totalSupplyLimit_ Maximum total supply (0 to use default)
     * @param perMint_ Amount per mint (0 to use default)
     * @param price_ Price per token (0 to use default)
     * @return tokenAddress The address of the deployed token proxy
     */
    function deployMeme(
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

        // Deploy clone using OpenZeppelin Clones
        tokenAddress = Clones.clone(implementation);
        require(tokenAddress != address(0), "Failed to deploy clone");
        
        // Initialize the clone
        MemeToken(tokenAddress).initialize(
            name,
            symbol,
            msg.sender,
            address(this),
            finalTotalSupplyLimit,
            finalPerMint,
            finalPrice
        );

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

        // Emit both events for backward compatibility
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
        
        emit MemeDeployed(
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
     * @dev Create a new Meme Token using minimal proxy (legacy function for backward compatibility)
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

        // Deploy clone using OpenZeppelin Clones
        tokenAddress = Clones.clone(implementation);
        require(tokenAddress != address(0), "Failed to deploy clone");
        
        // Initialize the clone
        MemeToken(tokenAddress).initialize(
            name,
            symbol,
            msg.sender,
            address(this),
            finalTotalSupplyLimit,
            finalPerMint,
            finalPrice
        );

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

        // Emit both events for backward compatibility
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
        
        emit MemeDeployed(
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

        // Deploy clone using OpenZeppelin Clones
        tokenAddress = Clones.clone(implementation);
        require(tokenAddress != address(0), "Failed to deploy clone");
        
        // Initialize the clone
        MemeToken(tokenAddress).initialize(
            name,
            symbol,
            msg.sender,
            address(this),
            finalTotalSupplyLimit,
            finalPerMint,
            finalPrice
        );

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

        // Emit both events for backward compatibility
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
        
        emit MemeDeployed(
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
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        if (amount == 0) {
            // Use default perMint amount
            token.mintByFactory(to);
        } else {
            // Use specified amount
            token.mintByFactory(to, amount);
        }
    }

    /**
     * @dev Mint Meme tokens by paying ETH
     * @param tokenAddress The token contract address
     * @param amount The amount to mint (0 to use default perMint)
     */
    function mintMeme(address tokenAddress, uint256 amount) external payable whenNotPaused nonReentrant {
        require(isTokenCreated[tokenAddress], "Token not created by this factory");
        
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Determine mint amount
        uint256 mintAmount = amount == 0 ? token.perMint() : amount;
        require(mintAmount > 0, "Mint amount must be greater than 0");
        
        // Calculate required payment
        uint256 requiredPayment = mintAmount * token.price();
        require(msg.value == requiredPayment, "Incorrect payment amount");
        
        // Calculate fee distribution (5% project, 5% liquidity, 90% issuer)
        uint256 projectFee = requiredPayment * 5 / 100; // 5%
        uint256 liquidityETH = requiredPayment * 5 / 100; // 5% ETH for liquidity
        uint256 issuerFee = requiredPayment - projectFee - liquidityETH; // 90%
        
        // Calculate liquidity token amount (5% of mintAmount)
        uint256 liquidityTokenAmount = mintAmount * 5 / 100; // 5% tokens for liquidity
        
        // Distribute fees
        if (projectFee > 0) {
            payable(owner()).transfer(projectFee);
        }
        if (issuerFee > 0) {
            payable(token.issuer()).transfer(issuerFee);
        }
        
        // Mint tokens to the caller (95% of mintAmount)
        uint256 userTokenAmount = mintAmount - liquidityTokenAmount;
        token.mintByFactory(msg.sender, userTokenAmount);
        
        // Add liquidity to Uniswap if we have liquidity amounts
        if (liquidityETH > 0 && liquidityTokenAmount > 0) {
            _addLiquidity(tokenAddress, liquidityTokenAmount, liquidityETH);
        }
        
        // Emit event
        emit MemeMinted(
            tokenAddress,
            msg.sender,
            userTokenAmount,
            requiredPayment,
            projectFee,
            issuerFee
        );
    }
    
    /**
     * @dev Internal function to add liquidity to Uniswap
     * @param tokenAddress The token contract address
     * @param tokenAmount The amount of tokens to add
     * @param ethAmount The amount of ETH to add
     */
    function _addLiquidity(address tokenAddress, uint256 tokenAmount, uint256 ethAmount) internal {
        IMemeToken token = IMemeToken(tokenAddress);
        
        // Check if pair exists, if not, create it
        address pair = uniswapV2Factory.getPair(tokenAddress, WETH);
        bool isFirstLiquidity = (pair == address(0));
        
        // If first liquidity, use mint price to determine ratio
        uint256 finalTokenAmount = tokenAmount;
        uint256 finalETHAmount = ethAmount;
        
        if (isFirstLiquidity) {
            uint256 mintPrice = token.price();
            // Calculate expected token amount based on mint price
            // If mint price is 0.001 ETH per token, then 1 ETH = 1000 tokens
            // So for ethAmount ETH, we need ethAmount * (1 / mintPrice) tokens
            if (mintPrice > 0) {
                uint256 expectedTokenAmount = (ethAmount * 10**18) / mintPrice;
                if (expectedTokenAmount < tokenAmount) {
                    // Adjust tokenAmount to match price
                    finalTokenAmount = expectedTokenAmount;
                } else if (expectedTokenAmount > tokenAmount) {
                    // Adjust ethAmount to match price
                    finalETHAmount = (tokenAmount * mintPrice) / 10**18;
                }
            }
        }
        
        // Mint tokens for liquidity to this contract
        token.mintByFactory(address(this), finalTokenAmount);
        
        // Approve router to spend tokens
        token.approve(address(uniswapV2Router), finalTokenAmount);
        
        // Calculate minimum amounts (allow 1% slippage)
        uint256 amountTokenMin = finalTokenAmount * 99 / 100;
        uint256 amountETHMin = finalETHAmount * 99 / 100;
        
        // Add liquidity
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapV2Router.addLiquidityETH{value: finalETHAmount}(
            tokenAddress,
            finalTokenAmount,
            amountTokenMin,
            amountETHMin,
            address(this), // LP tokens go to factory
            block.timestamp + 300 // 5 minutes deadline
        );
        
        // Update pair address mapping
        pair = uniswapV2Factory.getPair(tokenAddress, WETH);
        if (pair != address(0) && tokenPair[tokenAddress] == address(0)) {
            tokenPair[tokenAddress] = pair;
        }
        
        // Refund any excess tokens or ETH
        if (amountToken < finalTokenAmount) {
            token.transfer(owner(), finalTokenAmount - amountToken);
        }
        if (amountETH < finalETHAmount) {
            payable(owner()).transfer(finalETHAmount - amountETH);
        }
        
        emit LiquidityAdded(tokenAddress, pair, amountETH, amountToken, liquidity);
    }
    
    /**
     * @dev Buy Meme tokens from Uniswap if price is better than mint price
     * @param tokenAddress The token contract address
     * @param minTokenAmount Minimum tokens to receive (slippage protection)
     */
    function buyMeme(address tokenAddress, uint256 minTokenAmount) external payable whenNotPaused nonReentrant {
        require(isTokenCreated[tokenAddress], "Token not created by this factory");
        require(msg.value > 0, "Must send ETH");
        
        IMemeToken token = IMemeToken(tokenAddress);
        address pair = uniswapV2Factory.getPair(tokenAddress, WETH);
        require(pair != address(0), "Liquidity pool does not exist");
        
        // Get Uniswap price
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddress;
        
        uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(msg.value, path);
        uint256 uniswapTokenAmount = amountsOut[1];
        
        // Calculate mint price equivalent
        uint256 mintPrice = token.price();
        uint256 mintTokenAmount = (msg.value * 10**18) / mintPrice;
        
        // Only proceed if Uniswap price is better (more tokens for same ETH)
        require(uniswapTokenAmount >= mintTokenAmount, "Uniswap price not better than mint price");
        require(uniswapTokenAmount >= minTokenAmount, "Slippage too high");
        
        // Swap ETH for tokens
        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: msg.value}(
            minTokenAmount,
            path,
            msg.sender,
            block.timestamp + 300 // 5 minutes deadline
        );
        
        emit MemeBought(tokenAddress, msg.sender, msg.value, amounts[1]);
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

    /**
     * @dev Get token information using interface
     * @param tokenAddress The token contract address
     * @return name_ Token name
     * @return symbol_ Token symbol
     * @return totalSupply_ Current total supply
     * @return totalSupplyLimit_ Maximum total supply
     * @return perMint_ Amount per mint
     * @return price_ Price per token
     * @return issuer_ Token issuer
     * @return minted_ Total minted amount
     */
    function getTokenInfoByAddress(address tokenAddress) external view returns (
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 totalSupplyLimit_,
        uint256 perMint_,
        uint256 price_,
        address issuer_,
        uint256 minted_
    ) {
        require(isTokenCreated[tokenAddress], "Token not created by this factory");
        IMemeToken token = IMemeToken(tokenAddress);
        return token.getTokenInfo();
    }

    /**
     * @dev Check if a token can mint more tokens
     * @param tokenAddress The token contract address
     * @return True if the token can mint more tokens
     */
    function canTokenMint(address tokenAddress) external view returns (bool) {
        require(isTokenCreated[tokenAddress], "Token not created by this factory");
        IMemeToken token = IMemeToken(tokenAddress);
        return token.canMint();
    }

    /**
     * @dev Get remaining mintable amount for a token
     * @param tokenAddress The token contract address
     * @return The remaining mintable amount
     */
    function getTokenRemainingMintable(address tokenAddress) external view returns (uint256) {
        require(isTokenCreated[tokenAddress], "Token not created by this factory");
        IMemeToken token = IMemeToken(tokenAddress);
        return token.getRemainingMintable();
    }

    /**
     * @dev Get token balance for a specific address
     * @param tokenAddress The token contract address
     * @param account The account address
     * @return The token balance
     */
    function getTokenBalance(address tokenAddress, address account) external view returns (uint256) {
        require(isTokenCreated[tokenAddress], "Token not created by this factory");
        IMemeToken token = IMemeToken(tokenAddress);
        return token.balanceOf(account);
    }
}