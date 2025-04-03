// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import { Tests } from "@/02_security/core/Tests.sol";
import { KingFactory, King } from "@/02_security/levels/09_King/KingFactory.sol";
import { MaliciousKing } from "@/02_security/levels/09_King/MaliciousKing.sol";

contract TestKing is Tests {
    King private level;

    constructor() {
        levelFactory = new KingFactory();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance{ value: 1 ether }());
        level = King(levelAddress);
    }

    function attack() internal override {
        vm.startPrank(PLAYER);

        MaliciousKing maliciousKing = new MaliciousKing();
        maliciousKing.attack{ value: 1 ether }(levelAddress);

        assertEq(level._king(), address(maliciousKing));

        vm.stopPrank();
    }

    function testLevel() external {
        runLevel();
    }
}
