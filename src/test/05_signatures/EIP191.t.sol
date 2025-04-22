// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {EIP191} from "@/05_signatures/EIP191.sol";

contract EIP191Test is Test {
    // Deploy the eip191 contract
    EIP191 eip191;

    // Generate new address with this private key
    uint256 privateKey = 0xA11CE;
    address signer;

    function setUp() public {
        eip191 = new EIP191();
        // derive address from private key
        signer = vm.addr(privateKey);
    }

    function testSignatureVerificationEIP191() public view {
        // Raw message
        string memory message = "Hello from EIP-191!";

        // Hash raw message
        bytes32 rawMessageHash = keccak256(bytes(message));

        // Hash with prefix (EIP191)
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", rawMessageHash));

        // Generate signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);

        // Check the signature
        address recovered = eip191.verifySignature(message, v, r, s);

        // Check if signer address is matched
        assertEq(recovered, signer, "Recovered address does not match signer");
    }
}
