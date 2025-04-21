// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {SimpleSignature} from "@/05_signatures/SimpleSignature.sol";

contract SimpleSignatureTest is Test {
    SimpleSignature simpleSignatureContract;
    uint256 public privateKeySigner;
    address public signer;

    function setUp() public {
        // Add new instance of simple signature contract
        simpleSignatureContract = new SimpleSignature();

        // Set up private key signer address start with 0x...
        privateKeySigner = 0x123;
        signer = vm.addr(privateKeySigner);
    }

    function testSignatureVerification() public view {
        // Prepare data to sign
        bytes memory data = abi.encode("secret value");
        bytes32 hash = keccak256(data);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeySigner, hash);
        address recovered = simpleSignatureContract.verifySignature(data, v, r, s);

        assertEq(recovered, signer, "Signature verification failed");
    }

    function testSignatureVerificationFalse() public view {
        // Prepare data to sign
        bytes memory data = abi.encode("secret value");
        bytes32 hash = keccak256(data);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeySigner, hash);
        
        // Test with wrong passed data
        bytes memory dataTwo = abi.encode("secret value 2");
        address recovered = simpleSignatureContract.verifySignature(dataTwo, v, r, s);

        console.log("Signer: ", signer);
        console.log("Recovered: ", recovered);

        assertNotEq(recovered, signer, "Signature verification is successfull");
    }

    function testEmptyDataSignature() public view {
        bytes memory data = abi.encode("");
        bytes32 hash = keccak256(data);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeySigner, hash);
        address recovered = simpleSignatureContract.verifySignature(data, v, r, s);

        assertEq(recovered, signer, "Signature verification failed for empty data");
    }

    function testMismatchedHashFormat() public view {
    bytes memory data = abi.encode("secret value");

    // Add prefix for Ethereum signature
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uint256(data.length), data));

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeySigner, ethSignedMessageHash);

    address recovered = simpleSignatureContract.verifySignature(data, v, r, s);

    // Might or might not work depending on the format; assert accordingly
    assertNotEq(recovered, signer, "Mismatched hash formats shouldn't verify");
}

}