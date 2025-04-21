// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract SimpleSignature {
    // Function for signature check
    function verifySignature(bytes memory data, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {

        // Hash message data and store in one slot 32bytes
        bytes32 hash = keccak256(data);

        // Restore the signer address
        address recoverAddress = ecrecover(hash, v, r, s);

        // Check for zero address
        require(recoverAddress != address(0), "Invalid signature");

        // Return signer address
        return recoverAddress;
    }
}
