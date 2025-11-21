// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MemeFactory} from "../src/MemeFactory.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {IMemeToken} from "../src/IMemeToken.sol";
import {IUniswapV2Router, IUniswapV2Factory, IUniswapV2Pair} from "../src/IUniswapV2Router.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Interface for pair operations
interface IMockPair {
    function setReserves(uint112 _reserve0, uint112 _reserve1) external;
    function mint(address to, uint256 amount) external;
}

// Mock WETH
contract MockWETH is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {}
    
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

// Mock Uniswap V2 Pair
contract MockUniswapV2Pair is ERC20 {
    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;
    
    constructor(address _token0, address _token1) ERC20("Uniswap V2", "UNI-V2") {
        token0 = _token0;
        token1 = _token1;
    }
    
    // Allow receiving ETH
    receive() external payable {}
    
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        return (reserve0, reserve1, blockTimestampLast);
    }
    
    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = uint32(block.timestamp);
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock Uniswap V2 Factory
contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;
    
    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        return pairs[tokenA][tokenB];
    }
    
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Identical addresses");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(pairs[token0][token1] == address(0), "Pair exists");
        
        MockUniswapV2Pair newPair = new MockUniswapV2Pair(token0, token1);
        pair = address(newPair);
        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
    }
}

// Mock Uniswap V2 Router
contract MockUniswapV2Router {
    IUniswapV2Factory public factory;
    address public WETH;
    
    constructor(address _factory, address _WETH) {
        factory = IUniswapV2Factory(_factory);
        WETH = _WETH;
    }
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        require(deadline >= block.timestamp, "Expired");
        
        // Get or create pair
        address pair = factory.getPair(token, WETH);
        if (pair == address(0)) {
            pair = factory.createPair(token, WETH);
        }
        
        // Transfer tokens from sender
        require(ERC20(token).transferFrom(msg.sender, pair, amountTokenDesired), "Token transfer failed");
        
        // Transfer ETH to pair (simplified - just accept ETH, pair will handle it)
        // In real Uniswap, ETH is wrapped to WETH, but for mock we'll just track it
        // We need to ensure the pair contract can receive ETH
        (bool success, ) = payable(pair).call{value: msg.value}("");
        require(success, "ETH transfer failed");
        
        // Calculate liquidity (simplified: sqrt(x * y))
        uint256 liquidityAmount = sqrt(amountTokenDesired * msg.value);
        
        // Mint LP tokens
        IMockPair(payable(pair)).mint(to, liquidityAmount);
        
        // Update reserves
        IMockPair(payable(pair)).setReserves(uint112(amountTokenDesired), uint112(msg.value));
        
        return (amountTokenDesired, msg.value, liquidityAmount);
    }
    
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, "Expired");
        require(path.length == 2, "Invalid path");
        require(path[0] == WETH, "Invalid path");
        
        address pair = factory.getPair(path[0], path[1]);
        require(pair != address(0), "Pair does not exist");
        
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        
        // Determine which reserve is which
        bool token0IsWETH = IUniswapV2Pair(pair).token0() == WETH;
        uint112 reserveWETH = token0IsWETH ? reserve0 : reserve1;
        uint112 reserveToken = token0IsWETH ? reserve1 : reserve0;
        
        // Calculate output using constant product formula
        uint256 amountOut = (msg.value * reserveToken) / (reserveWETH + msg.value);
        require(amountOut >= amountOutMin, "Insufficient output amount");
        
        // Transfer tokens to user
        ERC20(path[1]).transfer(to, amountOut);
        
        // Update reserves
        uint112 newReserveWETH = uint112(reserveWETH + msg.value);
        uint112 newReserveToken = uint112(reserveToken - amountOut);
        if (token0IsWETH) {
            IMockPair(payable(pair)).setReserves(newReserveWETH, newReserveToken);
        } else {
            IMockPair(payable(pair)).setReserves(newReserveToken, newReserveWETH);
        }
        
        amounts = new uint256[](2);
        amounts[0] = msg.value;
        amounts[1] = amountOut;
    }
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts) {
        require(path.length == 2, "Invalid path");
        
        address pair = factory.getPair(path[0], path[1]);
        if (pair == address(0)) {
            amounts = new uint256[](2);
            amounts[0] = amountIn;
            amounts[1] = 0;
            return amounts;
        }
        
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        
        bool token0IsWETH = IUniswapV2Pair(pair).token0() == WETH;
        uint112 reserveWETH = token0IsWETH ? reserve0 : reserve1;
        uint112 reserveToken = token0IsWETH ? reserve1 : reserve0;
        
        uint256 amountOut = (amountIn * reserveToken) / (reserveWETH + amountIn);
        
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }
    
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

