// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract Level is Ownable {
    constructor(address owner_) Ownable(owner_) {}

    function createInstance(address _player) public payable virtual returns (address instanceAddr);

    function validateInstance(address payable _instance, address _player) public virtual returns (bool success);
}
