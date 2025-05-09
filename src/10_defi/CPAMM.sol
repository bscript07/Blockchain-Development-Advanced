// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error InsufficientLiquidity();
error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error InvalidToken();
error InsufficientAmount();

contract CPAMM is ERC20 {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA; // 256 bits == 1 slot in storage
    uint256 public reserveB; // 256 bits == 1 slot in storage

    constructor(address _tokenA, address _tokenB) ERC20("LPToken", "LPT") {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 shares) {
        if (reserveA > 0 || reserveB > 0) {
            if (reserveA * amountB != reserveB * amountA) {
                revert InsufficientLiquidity();
            }
        }

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (totalSupply() == 0) {
            shares = _sqrt(amountA * amountB); // how tokens can be minted
        } else {
            shares = _min((amountA * totalSupply()) / reserveA, (amountB * totalSupply()) / reserveB);
        }

        if (shares == 0) revert InsufficientLiquidityMinted();

        _mint(msg.sender, shares);
        _update(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function removeLiquidity(uint256 _shares) external returns (uint256 amountA, uint256 amountB) {
        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));

        amountA = (_shares * balanceA) / totalSupply();
        amountB = (_shares * balanceB) / totalSupply();

        if (amountA == 0 || amountB == 0) {
            revert InsufficientLiquidityBurned();
        }

        _burn(msg.sender, _shares);
        _update(balanceA - amountA, balanceB - amountB);

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function swap(address token, uint256 amountIn) external {
        if (token != address(tokenA) && token != address(tokenB)) {
            revert InvalidToken();
        }

        if (amountIn == 0) {
            revert InsufficientAmount();
        }

        bool isTokenA = token == address(tokenA);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) =
            isTokenA ? (tokenA, tokenB, reserveA, reserveB) : (tokenB, tokenA, reserveB, reserveA);

        tokenIn.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        tokenOut.transfer(msg.sender, amountOut);

        _update(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function _update(uint256 _reserveA, uint256 _reserveB) private {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x < y ? x : y;
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        } else {
            z = 0;
        }
    }
}
