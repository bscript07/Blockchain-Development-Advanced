// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {FunctionGuzzler} from "@/03_gas-optimizations/function-guzzler/FunctionGuzzler.sol";
import {OptimizedFunctionGuzzler} from "@/03_gas-optimizations/function-guzzler/OptimizedFunctionGuzzler.sol";

contract FunctionGuzzlerGasCompareTest is Test {
    // Contracts instances in state variables
    FunctionGuzzler public functionGuzzler;
    OptimizedFunctionGuzzler public optimizedFunctionGuzzler;

    address public user1;
    address public user2;

    function setUp() public {
        functionGuzzler = new FunctionGuzzler();
        optimizedFunctionGuzzler = new OptimizedFunctionGuzzler();

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // 1. Register users for testing original contract
        vm.prank(user1);
        functionGuzzler.registerUser();

        vm.prank(user2);
        functionGuzzler.registerUser();

         // 2. Register users for testing optimized contract
        vm.prank(user1);
        optimizedFunctionGuzzler.registerUser();

        vm.prank(user2);
        optimizedFunctionGuzzler.registerUser();
    }

    function testGasCompareRegisterUser() public {
        address newUser = makeAddr("newUser");

        // 1. Test original contract
        vm.prank(newUser);
        uint256 originalGasBefore = gasleft();
        functionGuzzler.registerUser();
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Reset user for optimized test
        newUser = makeAddr("newUser2");

        // 3. Test optimized contract
        vm.prank(newUser);
        uint256 optimizedGasBefore = gasleft();
        optimizedFunctionGuzzler.registerUser();
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("==== Gas Comparison for `registerUser` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasCompareAddValue() public {

        // 1. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        functionGuzzler.addValue(500);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimizedFunctionGuzzler.addValue(500);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("==== Gas Comparison for `addValue` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasCompareDeposit() public {

        // 1. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        functionGuzzler.deposit(5000);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimizedFunctionGuzzler.deposit(5000);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("==== Gas Comparison for `deposit` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasCompareFindUser() public view {

        // 1. Test original contract
        uint256 originalGasBefore = gasleft();
        functionGuzzler.findUser(user1);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        uint256 optimizedGasBefore = gasleft();
        optimizedFunctionGuzzler.findUser(user1);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("==== Gas Comparison for `findUser` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasCompareTransfer() public {

        // 1. Make deposits to both contracts
        vm.startPrank(user1);
        functionGuzzler.deposit(5000);
        optimizedFunctionGuzzler.deposit(5000);
        vm.stopPrank();

        // 2. Test original contract
        vm.prank(user1);
        uint256 originalGasBefore = gasleft();
        functionGuzzler.transfer(user2, 2500);
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 2. Test optimized contract
        vm.prank(user1);
        uint256 optimizedGasBefore = gasleft();
        optimizedFunctionGuzzler.transfer(user2, 2500);
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("==== Gas Comparison for `transfer` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasCompareSumValues() public {

        // 1. Add some values first to both contracts
        vm.startPrank(user1);
        functionGuzzler.addValue(100);
        functionGuzzler.addValue(200);
        functionGuzzler.addValue(300);

        optimizedFunctionGuzzler.addValue(100);
        optimizedFunctionGuzzler.addValue(200);
        optimizedFunctionGuzzler.addValue(300);
        vm.stopPrank();

        // 2. Test original contract
        uint256 originalGasBefore = gasleft();
        functionGuzzler.getAverageValue();
        uint256 originalGasAfter = gasleft();
        uint256 originalGasUsed = originalGasBefore - originalGasAfter;

        // 3. Test optimized contract
        uint256 optimizedGasBefore = gasleft();
        optimizedFunctionGuzzler.getAverageValue();
        uint256 optimizedGasAfter = gasleft();
        uint256 optimizedGasUsed = optimizedGasBefore - optimizedGasAfter;

        // 4. Compare results
        console.log("==== Gas Comparison for `getAverageValue` ====");
        console.log("Original gas used: ", originalGasUsed);
        console.log("Optimized gas used: ", optimizedGasUsed);

        if (originalGasUsed > optimizedGasUsed) {
            console.log("Gas saved: ", originalGasUsed - optimizedGasUsed);
            console.log("Percentage saved:", ((originalGasUsed - optimizedGasUsed) * 100) / originalGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedGasUsed - originalGasUsed);
            console.log("Percentage increase:", ((optimizedGasUsed - originalGasUsed) * 100) / originalGasUsed, "%");
        }
        console.log("=================================================");
    }
}