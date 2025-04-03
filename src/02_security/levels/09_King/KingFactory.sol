// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import { Level } from "@/02_security/core/Level.sol";
import { King } from "./King.sol";

contract KingFactory is Level(msg.sender) {
    function createInstance(address)
        public
        payable
        override
        returns (address instanceAddr)
    {
        instanceAddr = address(new King{ value: msg.value }());
    }

    function validateInstance(address payable _instance, address)
        public
        override
        returns (bool success)
    {
        King instance = King(_instance);

        (bool ok,) = address(instance).call{ value: 0 }("");
        if (ok) revert();
        success = instance._king() != address(this);
    }

    receive() external payable { }
}
