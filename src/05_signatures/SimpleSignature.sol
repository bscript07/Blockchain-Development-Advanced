// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract SimpleSignature {
    function verifySignature(bytes memory data, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                data // Data to sign
            )
        );

        // Recover the signer's address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Invalid signature");
        return signer;
    }
}
