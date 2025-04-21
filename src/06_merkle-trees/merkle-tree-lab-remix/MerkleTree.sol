// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ParticipantVerifier {
    bytes32 immutable rootHash;

    constructor(bytes32 _rootHash) {
        rootHash = _rootHash;
    }

    function isParticipant(address paricipant, bytes32[] calldata proof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(paricipant));

        return MerkleProof.verify(proof, rootHash, leaf);
    }
}

contract DogyCoin is ERC20, Ownable {
    bytes32 public immutable rootHash;

    mapping(address => bool) public claimed;

    event ClaimedRewards(address indexed user, uint256 amount);

    error InvalidProof();
    error AlreadyClaimed();

    constructor(address initialOwner, bytes32 _rootHash) ERC20("Dogycoin", "DGC") Ownable(initialOwner) {
        rootHash = _rootHash;
        _mint(initialOwner, 5_000_000 * 10 ** 18);
    }

    function claimAirdrop(uint256 amount, bytes32[] calldata proof) external {
        require(!claimed[msg.sender], AlreadyClaimed());
        require(MerkleProof.verify(proof, rootHash, keccak256(abi.encodePacked(msg.sender, amount))), InvalidProof());

        claimed[msg.sender] = true;

        _mint(msg.sender, amount);

        emit ClaimedRewards(msg.sender, amount);
    }
}
