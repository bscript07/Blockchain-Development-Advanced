// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import { Tests } from "@/02_security/core/Tests.sol";
import { PreservationFactory, Preservation } from "@/02_security/levels/16_Preservation/PreservationFactory.sol";
import { MaliciousPreservation } from "@/02_security/levels/16_Preservation/MaliciousPreservation.sol";

contract TestPreservation is Tests {
    Preservation private level;

    constructor() {
        levelFactory = new PreservationFactory();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance());
        level = Preservation(levelAddress);
    }

    function attack() internal override {
        vm.startPrank(PLAYER);

        MaliciousPreservation maliciousPreservation = new MaliciousPreservation();
        maliciousPreservation.attack(level);
        assertEq(level.owner(), PLAYER);

        vm.stopPrank();
    }

    function testLevel() external {
        runLevel();
    }
}
