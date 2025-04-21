// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {MerkleVerifier} from "@/06_merkle-trees/merkle-tree-lab-remix/MerkleOak.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleVerifierTest is Test {
    MerkleVerifier public verifier;
    address public owner;
    address public nonOwner;

    // Get initial Merkle root
    bytes32 public merkleRoot;

    // Addresses on participants
    address[] public participants;

    // Proofs dynamic array
    bytes32[] public proof;
    bytes32[] public invalidProof;

    function setUp() public {
        // Set up contract owner address
        owner = address(this);

        // Set up contract non-owner address
        nonOwner = address(0x123);

        // Set up participants
        participants = [
            address(0x0000000000000000000000000000000000000001),
            address(0x0000000000000000000000000000000000000002),
            address(0x0000000000000000000000000000000000000003)
        ];

        // 🧠 Use actual Merkle root from off-chain JSON
        merkleRoot = 0x08e117a4741e163ff51603b4c8f757163c947443e47282181c8bb827d9c59178;

        verifier = new MerkleVerifier(merkleRoot);

        // Initialize the proof with correct values
        proof.push(0xd52688a8f926c816ca1e079067caba944f158e764817b83fc43594370ca9cf62);
        proof.push(0x735c77c52a2b69afcd4e13c0a6ece7e4ccdf2b379d39417e21efe8cd10b5ff1b);
        proof.push(0x95650db08d5c4f6cddabf1718cd49d7374150a517abf06c90942b440712569f9);
        proof.push(0x8e534a9e9750df31a2fbe7f7c1593c70980eca23dae471bb0ff8223d941cc0c4);

        // Initialize invalid proof (incorrect values)
        invalidProof.push(0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef);
        invalidProof.push(0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890);
        invalidProof.push(0x7890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456);
        invalidProof.push(0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd);
    }

    // Root setting and updating
    function testRootSetting() public view {
        assertEq(verifier.merkleRoot(), merkleRoot);
    }

    function testUpdateRootAsOwner() public {
        bytes32 newRoot = keccak256(abi.encodePacked("newRoot"));
        verifier.updateRoot(newRoot);
        assertEq(verifier.merkleRoot(), newRoot);
    }

    function testUpdateRootAsNonOwner() public {
        bytes32 newRoot = keccak256(abi.encodePacked("newRoot"));

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        vm.prank(nonOwner);
        verifier.updateRoot(newRoot);
    }

    // Proof verification
    function testValidProof() public view {
        address addr = participants[0];

        // 🟢 Explicitly call the verifier with the correct proof array
        bool isValid = verifier.verifyParticipant(addr, proof);

        // 🟢 Assert that proof is valid
        assertTrue(isValid, "Expected valid Merkle proof to pass verification");
    }

    function testInvalidProof() public {
        address fakeAddress = address(0x888);
        vm.expectRevert(abi.encodeWithSelector(MerkleVerifier.InvalidMerkleProof.selector, fakeAddress));
        verifier.verifyParticipant(fakeAddress, invalidProof);
    }

    // Access control
    function testAccessControl() public {
        bytes32 newRoot = keccak256(abi.encodePacked("Unauthorized"));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        vm.prank(nonOwner);
        verifier.updateRoot(newRoot);
    }

    // Gas optimization
    function testGasUsageForOptimization() public view {
        // 👨🏻‍💼 Get first participant
        address addr = participants[0];

        // ⛽ Start gas value
        uint256 startGas = gasleft();

        // 🟢 Explicitly call the verifier with the correct proof array
        verifier.verifyParticipant(addr, proof);

        uint256 gasUsed = startGas - gasleft();
        console.log("Gas used for proof verification:", gasUsed);

        assertTrue(gasUsed < 50000, "Gas usage for valid proof is too high");
    }

    // Invalid proof rejection
    function testInvalidProofRejection() public {
        address fakeAddress = address(0x12345);
        vm.expectRevert(abi.encodeWithSelector(MerkleVerifier.InvalidMerkleProof.selector, fakeAddress));
        verifier.verifyParticipant(fakeAddress, invalidProof);
    }
}
