// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import { Level } from "@/02_security/core/Level.sol";
import { Elevator } from "./Elevator.sol";

contract ElevatorFactory is Level(msg.sender) {
    function createInstance(address) public payable override returns (address instanceAddr) {
        instanceAddr = address(new Elevator());
    }

    function validateInstance(address payable _instance, address) public view override returns (bool success) {
        success = Elevator(_instance).top();
    }
}
