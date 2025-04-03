// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";

import {StakingContract} from "@/03_gas-optimizations/staking-contract/StakingContract.sol";
import {OptimizedStakingContract} from "@/03_gas-optimizations/staking-contract/OptimizedStakingContract.sol";
import {OptimizedERC20} from "@/03_gas-optimizations/standart-erc20/OptimizedERC20.sol";

contract StakingContractGasCompareTest is Test {
    uint256 constant REWARD_RATE = 100; // 100%

    StakingContract public originalContract;
    OptimizedStakingContract public optimizedContract;
    OptimizedERC20 public token;

    address public lili; // user named lili
    address public gogo; // user named gogo

    function setUp() public {

        // 1. Deploy the ERC20 token
        token = new OptimizedERC20("Test TKN", "TKN", 18, 1000000 * 10 ** 18); // 1m tokens

        // 2. Deploy staking contracts with same rewards rate
        originalContract = new StakingContract(address(token));
        optimizedContract = new OptimizedStakingContract(address(token), REWARD_RATE);

        // 3. Setup test users
        lili = makeAddr("lili");
        gogo = makeAddr("gogo");

        // 4. Send tokens to my users
        token.transfer(lili, 10000 * 10 ** 18); // 10k tokens for lili
        token.transfer(gogo, 10000 * 10 ** 18); // 10k tokens for gogo 

        // 5. Approve tokens for both contracts first for gosho contract after that for pesho contract
        vm.startPrank(lili);
        token.approve(address(originalContract), type(uint256).max);
        token.approve(address(optimizedContract), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(gogo);
        token.approve(address(originalContract), type(uint256).max);
        token.approve(address(optimizedContract), type(uint256).max);
        vm.stopPrank();
    }

    function testGasCompareStake() public {
        // 1. Test original contract
        vm.prank(lili);
        uint256 originalContractGasBefore = gasleft();
        originalContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        uint256 originalContractGasAfter = gasleft();
        uint256 originalContractGasUsed = originalContractGasBefore - originalContractGasAfter;

        // 2. Test optimized contract
        vm.prank(lili);
        uint256 optimizedContractGasBefore = gasleft();
        optimizedContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        uint256 optimizedContractGasAfter = gasleft();
        uint256 optimizedContractGasUsed = optimizedContractGasBefore - optimizedContractGasAfter;

        // 3. Compare results 

        console.log("==== Gas Comparison for `stake` ====");
        console.log("Original contract gas used: ", originalContractGasUsed);
        console.log("Optimized contract gas used: ", optimizedContractGasUsed);

        if (originalContractGasUsed > optimizedContractGasUsed) {
            console.log("Gas saved: ", originalContractGasUsed - optimizedContractGasUsed);
            console.log("Percentage saved:", ((originalContractGasUsed - optimizedContractGasUsed) * 100) / originalContractGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedContractGasUsed - originalContractGasUsed);
            console.log("Percentage increase:", ((optimizedContractGasUsed - originalContractGasUsed) * 100) / originalContractGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasCompareWithdraw() public {

        // 1. First stake some tokens in both contracts
        vm.startPrank(lili);
        originalContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        optimizedContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        vm.stopPrank();

        // 2. Mine some blocks to accumulate rewards
        vm.roll(block.number + 100);

        // 3. Test original contract
        vm.prank(lili);
        uint256 originalContractGasBefore = gasleft();
        originalContract.withdraw(500 * 10 ** 18); // 500 tokens for withdraw
        uint256 originalContractGasAfter = gasleft();
        uint256 originalContractGasUsed = originalContractGasBefore - originalContractGasAfter;

        // 4. Test optimized contract
        vm.prank(lili);
        uint256 optimizedContractGasBefore = gasleft();
        optimizedContract.withdraw(500 * 10 ** 18); // 500 tokens for withdraw
        uint256 optimizedContractGasAfter = gasleft();
        uint256 optimizedContractGasUsed = optimizedContractGasBefore - optimizedContractGasAfter;

        // 3. Compare results 

        console.log("==== Gas Comparison for `withdraw` ====");
        console.log("Original contract gas used: ", originalContractGasUsed);
        console.log("Optimized contract gas used: ", optimizedContractGasUsed);

        if (originalContractGasUsed > optimizedContractGasUsed) {
            console.log("Gas saved: ", originalContractGasUsed - optimizedContractGasUsed);
            console.log("Percentage saved:", ((originalContractGasUsed - optimizedContractGasUsed) * 100) / originalContractGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedContractGasUsed - originalContractGasUsed);
            console.log("Percentage increase:", ((optimizedContractGasUsed - originalContractGasUsed) * 100) / originalContractGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasCompareClaimReward() public {

        // 1. First stake some tokens in both contracts
        vm.startPrank(lili);
        originalContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        optimizedContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        vm.stopPrank();

        // 2. Mine some blocks to accumulate rewards
        vm.roll(block.number + 100);

        // 3. Test original contract
        vm.prank(lili);
        uint256 originalContractGasBefore = gasleft();
        originalContract.claimReward();
        uint256 originalContractGasAfter = gasleft();
        uint256 originalContractGasUsed = originalContractGasBefore - originalContractGasAfter;

        // 4. Test optimized contract
        vm.prank(lili);
        uint256 optimizedContractGasBefore = gasleft();
        optimizedContract.claimReward(); 
        uint256 optimizedContractGasAfter = gasleft();
        uint256 optimizedContractGasUsed = optimizedContractGasBefore - optimizedContractGasAfter;

        // 3. Compare results 

        console.log("==== Gas Comparison for `claimReward` ====");
        console.log("Original contract gas used: ", originalContractGasUsed);
        console.log("Optimized contract gas used: ", optimizedContractGasUsed);

        if (originalContractGasUsed > optimizedContractGasUsed) {
            console.log("Gas saved: ", originalContractGasUsed - optimizedContractGasUsed);
            console.log("Percentage saved:", ((originalContractGasUsed - optimizedContractGasUsed) * 100) / originalContractGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedContractGasUsed - originalContractGasUsed);
            console.log("Percentage increase:", ((optimizedContractGasUsed - originalContractGasUsed) * 100) / originalContractGasUsed, "%");
        }
        console.log("=================================================");
    }

    function testGasComparePendingReward() public {

        // 1. First stake some tokens in both contracts
        vm.startPrank(lili);
        originalContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        optimizedContract.stake(1000 * 10 ** 18); // 1k tokens for stake
        vm.stopPrank();

        // 2. Mine some blocks to accumulate rewards
        vm.roll(block.number + 100);

        // 3. Test original contract
        vm.prank(lili);
        uint256 originalContractGasBefore = gasleft();
        originalContract.pendingReward(lili);
        uint256 originalContractGasAfter = gasleft();
        uint256 originalContractGasUsed = originalContractGasBefore - originalContractGasAfter;

        // 4. Test optimized contract
        vm.prank(lili);
        uint256 optimizedContractGasBefore = gasleft();
        optimizedContract.getPendingReward(lili); 
        uint256 optimizedContractGasAfter = gasleft();
        uint256 optimizedContractGasUsed = optimizedContractGasBefore - optimizedContractGasAfter;

        // 3. Compare results 

        console.log("==== Gas Comparison for `pendingReward` ====");
        console.log("Original contract gas used: ", originalContractGasUsed);
        console.log("Optimized contract gas used: ", optimizedContractGasUsed);

        if (originalContractGasUsed > optimizedContractGasUsed) {
            console.log("Gas saved: ", originalContractGasUsed - optimizedContractGasUsed);
            console.log("Percentage saved:", ((originalContractGasUsed - optimizedContractGasUsed) * 100) / originalContractGasUsed, "%");
        } else {
            console.log("Gas increase: ", optimizedContractGasUsed - originalContractGasUsed);
            console.log("Percentage increase:", ((optimizedContractGasUsed - originalContractGasUsed) * 100) / originalContractGasUsed, "%");
        }
        console.log("=================================================");
    }
}