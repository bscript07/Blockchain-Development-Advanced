// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import { Level } from "@/02_security/core/Level.sol";
import { DexTwo, SwappableTokenTwo, IERC20 } from "./DexTwo.sol";

contract DexTwoFactory is Level(msg.sender) {
    function createInstance(address _player) public payable override returns (address instanceAddr) {
        DexTwo instance = new DexTwo();
        instanceAddr = address(instance);

        SwappableTokenTwo tokenInstance = new SwappableTokenTwo(instanceAddr, "Token 1", "TKN1", 110);
        SwappableTokenTwo tokenInstanceTwo = new SwappableTokenTwo(instanceAddr, "Token 2", "TKN2", 110);
        address tokenInstanceAddress = address(tokenInstance);
        address tokenInstanceTwoAddress = address(tokenInstanceTwo);

        instance.setTokens(tokenInstanceAddress, tokenInstanceTwoAddress);
        tokenInstance.approve(instanceAddr, 100);
        tokenInstanceTwo.approve(instanceAddr, 100);
        instance.add_liquidity(tokenInstanceAddress, 100);
        instance.add_liquidity(tokenInstanceTwoAddress, 100);
        tokenInstance.transfer(_player, 10);
        tokenInstanceTwo.transfer(_player, 10);
    }

    function validateInstance(address payable _instance, address) public view override returns (bool success) {
        address token1 = DexTwo(_instance).token1();
        address token2 = DexTwo(_instance).token2();
        success = IERC20(token1).balanceOf(_instance) == 0 || IERC20(token2).balanceOf(_instance) == 0;
    }
}
