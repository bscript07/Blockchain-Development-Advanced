// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import { Level } from "@/02_security/core/Level.sol";
import { Preservation, LibraryContract } from "./Preservation.sol";

contract PreservationFactory is Level(msg.sender) {
    function createInstance(address) public payable override returns (address instanceAddr) {
        address timeZone1Library = address(new LibraryContract());
        address timeZone2Library = address(new LibraryContract());

        instanceAddr = address(new Preservation(timeZone1Library, timeZone2Library));
    }

    function validateInstance(address payable _instance, address _player) public view override returns (bool success) {
        success = Preservation(_instance).owner() == _player;
    }
}
