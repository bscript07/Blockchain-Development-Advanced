// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {SimpleSignature} from "@/04_signatures/SimpleSignature.sol";

contract SimpleSignatureTest is Test {
    SimpleSignature simpleSignatureContract;
    uint256 privateKeySigner;
    address signer;

    function setUp() public {
        simpleSignatureContract = new SimpleSignature();
        privateKeySigner = 0x11;
        signer = vm.addr(privateKeySigner);
    }

    function testSignatureVerification() public view {
        // Prepare data to sign
        bytes memory data = abi.encode("secret value");
        bytes32 hash = keccak256(data);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeySigner, hash);
        address recovered = simpleSignatureContract.verifySignature(data, v, r, s);

        console.log("Recovered", recovered);

        assertNotEq(recovered, signer, "Signature verification is successfull");
    }
}