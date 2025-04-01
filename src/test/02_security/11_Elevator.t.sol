// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {Tests} from "@/02_security/core/Tests.sol";
import {ElevatorFactory, Elevator} from "@/02_security/levels/11_Elevator/ElevatorFactory.sol";
import {MaliciousElevator} from "@/02_security/levels/11_Elevator/MaliciousElevator.sol";

contract TestElevator is Tests {
    Elevator private level;


    constructor() {
        levelFactory = new ElevatorFactory();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance());
        level = Elevator(levelAddress);
    }

    function attack() internal override {
        vm.startPrank(PLAYER);

        MaliciousElevator maliciousElevator = new MaliciousElevator(levelAddress);
        maliciousElevator.attack();
        assertTrue(level.top());

        vm.stopPrank();
    }


    function testLevel() external {
        runLevel();
    }
}