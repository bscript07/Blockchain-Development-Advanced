// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {CPAMM} from "@/10_defi/CPAMM.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    InsufficientLiquidity,
    InsufficientLiquidityMinted,
    InsufficientLiquidityBurned,
    InvalidToken,
    InsufficientAmount
} from "@/10_defi/CPAMM.sol";

// Mock ERC20 for testing
contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

contract CPAMMTest is Test {
    // Set CPAMM contract
    CPAMM public cpamm;

    // Set mock ERC20 tokenA
    MockERC20 public tokenAMock;

    // Set mock ERC20 tokenB
    MockERC20 public tokenBMock;

    address public owner;
    address public user1;
    address public user2;

    uint256 public constant INITIAL_SUPPLY = 1000 ether;
    uint256 public constant INITIAL_LIQUIDITY_TOKEN_A = 100 ether;
    uint256 public constant INITIAL_LIQUIDITY_TOKEN_B = 100 ether;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy mock tokens
        tokenAMock = new MockERC20("Token A", "TKA", 8);
        tokenBMock = new MockERC20("Token B", "TKB", 8);

        // Deploy CPAMM
        cpamm = new CPAMM(address(tokenAMock), address(tokenBMock));

        // Mint initial tokens to users and owner

        // Owner mint tokens from initial supply
        tokenAMock.mint(owner, INITIAL_SUPPLY);
        tokenBMock.mint(owner, INITIAL_SUPPLY);

        // User one mint tokens from initial supply
        tokenAMock.mint(user1, INITIAL_SUPPLY);
        tokenBMock.mint(user1, INITIAL_SUPPLY);

        // User two mint tokens from initial supply
        tokenAMock.mint(user2, INITIAL_SUPPLY);
        tokenBMock.mint(user2, INITIAL_SUPPLY);
    }

    function testInitialState() public view {
        assertEq(address(cpamm.tokenA()), address(tokenAMock));
        assertEq(address(cpamm.tokenB()), address(tokenBMock));
        assertEq(cpamm.reserveA(), 0);
        assertEq(cpamm.reserveB(), 0);
        assertEq(cpamm.totalSupply(), 0);
    }

    function testAddInitialLiquidity() public {
        // Set owner for the next function call execution
        vm.startPrank(owner);

        // Approve tokens 100 ethers for TOKEN_A and 100 ethers for TOKEN_B
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);

        // We can't directly call _sqrt since it's private, but we can verify the same logic
        uint256 expectedShares = sqrt(INITIAL_LIQUIDITY_TOKEN_A * INITIAL_LIQUIDITY_TOKEN_B);
        uint256 shares = cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        assertEq(shares, expectedShares);
        assertEq(cpamm.reserveA(), INITIAL_LIQUIDITY_TOKEN_A);
        assertEq(cpamm.reserveB(), INITIAL_LIQUIDITY_TOKEN_B);
        assertEq(cpamm.balanceOf(owner), expectedShares);
        assertEq(tokenAMock.balanceOf(address(cpamm)), INITIAL_LIQUIDITY_TOKEN_A);
        assertEq(tokenBMock.balanceOf(address(cpamm)), INITIAL_LIQUIDITY_TOKEN_B);
    }

    function testAddSubsequentLiquidity() public {
        // First add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        uint256 initialShares = cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        // Now add more liquidity with user1
        vm.startPrank(user1);
        uint256 additionalA = 500 ether;
        // Need to maintain the ratio
        uint256 additionalB = (additionalA * INITIAL_LIQUIDITY_TOKEN_B) / INITIAL_LIQUIDITY_TOKEN_A;

        tokenAMock.approve(address(cpamm), additionalA);
        tokenBMock.approve(address(cpamm), additionalB);

        uint256 expectedShares = (additionalA * initialShares) / INITIAL_LIQUIDITY_TOKEN_A;
        uint256 shares = cpamm.addLiquidity(additionalA, additionalB);
        vm.stopPrank();

        assertEq(shares, expectedShares);
        assertEq(cpamm.reserveA(), INITIAL_LIQUIDITY_TOKEN_A + additionalA);
        assertEq(cpamm.reserveB(), INITIAL_LIQUIDITY_TOKEN_B + additionalB);
        assertEq(cpamm.balanceOf(user1), expectedShares);
    }

    function testAddLiquidityWithInvalidRatio() public {
        // First add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        // Try to add liquidity with incorrect ratio
        vm.startPrank(user1);
        uint256 additionalA = 500 ether;
        uint256 incorrectAdditionalB = 1500 ether; // Intentionally wrong ratio

        tokenAMock.approve(address(cpamm), additionalA);
        tokenBMock.approve(address(cpamm), incorrectAdditionalB);

        vm.expectRevert(InsufficientLiquidity.selector);
        cpamm.addLiquidity(additionalA, incorrectAdditionalB);
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        // First add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        uint256 shares = cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);

        // Calculate expected amounts to receive
        uint256 sharesToRemove = shares / 2; // Remove half
        uint256 expectedAmountA = (sharesToRemove * INITIAL_LIQUIDITY_TOKEN_A) / shares;
        uint256 expectedAmountB = (sharesToRemove * INITIAL_LIQUIDITY_TOKEN_B) / shares;

        uint256 balanceABefore = tokenAMock.balanceOf(owner);
        uint256 balanceBBefore = tokenBMock.balanceOf(owner);

        // Remove liquidity
        (uint256 amountA, uint256 amountB) = cpamm.removeLiquidity(sharesToRemove);
        vm.stopPrank();

        // Verify returned amounts
        assertEq(amountA, expectedAmountA);
        assertEq(amountB, expectedAmountB);

        // Verify balances
        assertEq(tokenAMock.balanceOf(owner), balanceABefore + expectedAmountA);
        assertEq(tokenBMock.balanceOf(owner), balanceBBefore + expectedAmountB);

        // Verify reserves
        assertEq(cpamm.reserveA(), INITIAL_LIQUIDITY_TOKEN_A - expectedAmountA);
        assertEq(cpamm.reserveB(), INITIAL_LIQUIDITY_TOKEN_B - expectedAmountB);

        // Verify LP tokens
        assertEq(cpamm.balanceOf(owner), shares - sharesToRemove);
    }

    function testSwapTokenAForTokenB() public {
        // First add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        // Swap tokens with user1
        vm.startPrank(user1);
        uint256 amountIn = 10 ether;
        tokenAMock.approve(address(cpamm), amountIn);

        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 expectedAmountOut =
            (INITIAL_LIQUIDITY_TOKEN_B * amountInWithFee) / (INITIAL_LIQUIDITY_TOKEN_A + amountInWithFee);

        uint256 balanceBBefore = tokenBMock.balanceOf(user1);

        cpamm.swap(address(tokenAMock), amountIn);
        vm.stopPrank();

        // Verify balances and reserves
        assertEq(tokenBMock.balanceOf(user1), balanceBBefore + expectedAmountOut);
        assertEq(cpamm.reserveA(), INITIAL_LIQUIDITY_TOKEN_A + amountIn);
        assertEq(cpamm.reserveB(), INITIAL_LIQUIDITY_TOKEN_B - expectedAmountOut);
    }

    function testSwapTokenBForTokenA() public {
        // First add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        // Swap tokens with user1
        vm.startPrank(user1);
        uint256 amountIn = 10 ether;
        tokenBMock.approve(address(cpamm), amountIn);

        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 expectedAmountOut =
            (INITIAL_LIQUIDITY_TOKEN_A * amountInWithFee) / (INITIAL_LIQUIDITY_TOKEN_B + amountInWithFee);

        uint256 balanceABefore = tokenAMock.balanceOf(user1);

        cpamm.swap(address(tokenBMock), amountIn);
        vm.stopPrank();

        // Verify balances and reserves
        assertEq(tokenAMock.balanceOf(user1), balanceABefore + expectedAmountOut);
        assertEq(cpamm.reserveB(), INITIAL_LIQUIDITY_TOKEN_B + amountIn);
        assertEq(cpamm.reserveA(), INITIAL_LIQUIDITY_TOKEN_A - expectedAmountOut);
    }

    function testSwapInvalidToken() public {
        // First add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        // Try to swap with invalid token address
        vm.startPrank(user1);
        address invalidToken = makeAddr("user3");

        vm.expectRevert(InvalidToken.selector);
        cpamm.swap(invalidToken, 10 ether);
        vm.stopPrank();
    }

    function testSwapZeroAmount() public {
        // First add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        // Try to swap with zero amount
        vm.startPrank(user1);
        tokenAMock.approve(address(cpamm), 0);

        vm.expectRevert(InsufficientAmount.selector);
        cpamm.swap(address(tokenAMock), 0);
        vm.stopPrank();
    }

    function testMultipleOperations() public {
        // Add initial liquidity
        vm.startPrank(owner);
        tokenAMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_A);
        tokenBMock.approve(address(cpamm), INITIAL_LIQUIDITY_TOKEN_B);
        uint256 initialLpTokens = cpamm.addLiquidity(INITIAL_LIQUIDITY_TOKEN_A, INITIAL_LIQUIDITY_TOKEN_B);
        vm.stopPrank();

        // User1 swaps some tokens
        vm.startPrank(user1);
        uint256 amountIn = 10 ether;
        tokenAMock.approve(address(cpamm), amountIn);
        cpamm.swap(address(tokenAMock), amountIn);
        vm.stopPrank();

        // Owner removes some liquidity
        vm.startPrank(owner);
        uint256 lpToRemove = initialLpTokens / 2;
        cpamm.removeLiquidity(lpToRemove);
        vm.stopPrank();

        // User2 adds more liquidity
        vm.startPrank(user2);
        uint256 currentReserveA = cpamm.reserveA();
        uint256 currentReserveB = cpamm.reserveB();
        uint256 addA = 10 ether;
        uint256 addB = (addA * currentReserveB) / currentReserveA;

        tokenAMock.approve(address(cpamm), addA);
        tokenBMock.approve(address(cpamm), addB);

        cpamm.addLiquidity(addA, addB);
        vm.stopPrank();

        // User1 swaps again
        vm.startPrank(user1);
        uint256 amountBIn = 5 ether;
        tokenBMock.approve(address(cpamm), amountBIn);
        cpamm.swap(address(tokenBMock), amountBIn);
        vm.stopPrank();

        // Verify final state is consistent
        uint256 finalReserveA = cpamm.reserveA();
        uint256 finalReserveB = cpamm.reserveB();
        assertEq(finalReserveA, tokenAMock.balanceOf(address(cpamm)));
        assertEq(finalReserveB, tokenBMock.balanceOf(address(cpamm)));
    }

    // Helper functions for testing - reimplementing contract logic
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
        } else {
            z = 0;
        }
    }
}
