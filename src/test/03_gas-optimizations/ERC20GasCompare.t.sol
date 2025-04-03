// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { StandardERC20 } from
    "@/03_gas-optimizations/standart-erc20/StandardERC20.sol";
import { OptimizedERC20 } from
    "@/03_gas-optimizations/standart-erc20/OptimizedERC20.sol";

contract ERC20GasCompareTest is Test {
    StandardERC20 public standardERC20;
    OptimizedERC20 public optimizedERC20;

    address public deployer;
    address public user1;
    address public user2;

    function setUp() public {
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        standardERC20 =
            new StandardERC20("Test TKN", "TST", 18, 5000000 * 10 ** 18);
        optimizedERC20 =
            new OptimizedERC20("Test TKN", "TST", 18, 5000000 * 10 ** 18);

        standardERC20.transfer(user1, 500000 * 10 ** 18);
        optimizedERC20.transfer(user1, 500000 * 10 ** 18);
    }

    function testGasCompareDeploy() public {
        uint256 originalGasBefore = gasleft();
        new StandardERC20("Test TKN", "TST", 18, 5000000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        uint256 optimizedGasBefore = gasleft();
        new OptimizedERC20("Test TKN", "TST", 18, 5000000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        console.log("==== Gas Comparison for `deployment` ====");
        console.log("Original gas used:", originalGasUsed);
        console.log("Optimized gas used:", optimizedGasUsed);
    }

    function testGasCompareTransfer() public {
        // 1. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        standardERC20.transfer(user2, 5000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimizedERC20.transfer(user2, 5000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 3. Compare results
        console.log("==== Gas Comparison for `transfer` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log(
                "Percentage saved:",
                ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed,
                "%"
            );
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log(
                "Percentage increase:",
                ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed,
                "%"
            );
        }
        console.log("=================================================");
    }

    function testGasCompareApprove() public {
        // 1. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        standardERC20.approve(user2, 5000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimizedERC20.approve(user2, 5000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 3. Compare results
        console.log("==== Gas Comparison for `approve` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log(
                "Percentage saved:",
                ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed,
                "%"
            );
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log(
                "Percentage increase:",
                ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed,
                "%"
            );
        }
        console.log("=================================================");
    }

    function testGasCompareTransferFrom() public {
        // 1. Approve tokens for both contracts
        vm.startPrank(user1);
        standardERC20.approve(address(this), 50000 * 10 ** 18);
        optimizedERC20.approve(address(this), 50000 * 10 ** 18);

        vm.stopPrank();

        // 2. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        standardERC20.transferFrom(user1, user2, 5000 * 10 ** 18);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 3. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimizedERC20.transferFrom(user1, user2, 5000 * 10 ** 18);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("==== Gas Comparison for `approve` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log(
                "Percentage saved:",
                ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed,
                "%"
            );
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log(
                "Percentage increase:",
                ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed,
                "%"
            );
        }
        console.log("=================================================");
    }
}
