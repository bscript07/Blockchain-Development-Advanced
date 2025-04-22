// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract EIP191 {
    function verifySignature(string calldata message, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes32 rawMessageHash = keccak256(bytes(message));

        // prepend "\x19Ethereum Signed Message:\n" + length
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", rawMessageHash));

        // Recover the signer
        address signer = ecrecover(messageHash, v, r, s);

        // Check for zero address signer
        require(signer != address(0), "Invalid signature");

        // Return signer
        return signer;
    }
}
