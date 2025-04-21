// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {ERC1155} from "@/04_exercise-security-and-gas-optimizations/erc1155/ERC1155.sol";

contract ERC1155Test is Test {
    ERC1155 erc1155;
    address public user1;
    address public user2;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }
}
