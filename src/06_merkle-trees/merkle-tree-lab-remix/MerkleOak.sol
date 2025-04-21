// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleVerifier is Ownable {
    bytes32 public merkleRoot;

    // Event when the Merkle root is updated
    event MerkleRootUpdated(bytes32 newRoot);

    // Event when the proof verification is performed
    event ProofVerified(address participant, bool valid);

    // Custom error for failed proof verification
    error InvalidMerkleProof(address participant);

    // Custom error for unauthorized access
    error Unauthorized();

    // Constructor to set the initial Merkle root and call Ownable's constructor
    constructor(bytes32 _initialRoot) Ownable(msg.sender) {
        merkleRoot = _initialRoot;
        // Emit hash root when contract is deploying
        emit MerkleRootUpdated(_initialRoot);
    }

    // 🔐 Only the owner can update the Merkle root
    function updateRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
        // Emit updated hash root
        emit MerkleRootUpdated(_newRoot);
    }

    // ✅ Anyone can verify if an address is in the tree
    function verifyParticipant(address participant, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(participant));

        // Verify the Merkle proof
        bool validProof = MerkleProof.verify(proof, merkleRoot, leaf);

        if (!validProof) {
            revert InvalidMerkleProof(participant);
        }

        return validProof;
    }

    // 📣 Optional version that emits event
    function verifyAndEmitEvents(address participant, bytes32[] calldata proof) external returns (bool valid) {
        valid = verifyParticipant(participant, proof);
        // Emit hash root when participant proof is valid
        emit ProofVerified(participant, valid);
        return valid;
    }

    // ❌ Function to simulate unauthorized access (Example)
    function unauthorizedFunc() external pure {
        revert Unauthorized();
    }
}
