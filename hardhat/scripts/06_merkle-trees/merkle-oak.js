const { MerkleTree } = require("merkletreejs");
const { ethers } = require("hardhat");
const fs = require("fs");

// 🧑‍🤝‍🧑 List of charity tournament participants (Ethereum addresses)
const participants = ["0x0000000000000000000000000000000000000001",
    "0x0000000000000000000000000000000000000002",
    "0x0000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000005",
    "0x0000000000000000000000000000000000000006",
    "0x0000000000000000000000000000000000000007",
    "0x0000000000000000000000000000000000000008",
    "0x0000000000000000000000000000000000000009",
    "0x0000000000000000000000000000000000000010",
    "0x0000000000000000000000000000000000000011"
];

// 🌿 Step 1: Create leaf nodes by hashing participant addresses
const leaves = participants.map((participant) => ethers.keccak256(participant));
console.log("Leaves: ", leaves);

// 🌳 Step 2: Build the Merkle tree using the leaves
const tree = new MerkleTree(leaves, ethers.keccak256, {
    duplicateOdd: false,
    sortPairs: true
});
console.log("Tree: ", tree.toString());

// 🔗 Step 3: Get the root of the Merkle tree (used in the smart contract)
const root = tree.getHexRoot();
console.log("Root: ", root);

// 🧪 Step 4: Verify one participant's proof off-chain
const leaf = ethers.keccak256("0x0000000000000000000000000000000000000007"); // This is the user you're verifying
const proof = tree.getProof(leaf); // Get the Merkle proof for this leaf ...0007 ended address

// ✅ Step 5: Use the proof to verify if this address is in the tree
const isProofValid = tree.verify(proof, leaf, root); // Returns true or false
console.log("Is proof valid: ", isProofValid); // Should print true


// 📤 Step 6: Save All Proofs and Root to JSON (for use in contracts, frontend)
const proofs = participants.map((participant, index) => {
    return {
        address: participant,
        proof: tree
        .getProof(leaves[index])  // Get the proof for this leaf
        .map((participant) => "0x" + participant.data.toString("hex")) // Convert buffers to hex strings
    };
});

// 📦 Create final output object
const output = {
    root: root, // Merkle root
    proofs: proofs // All address-specific proofs
}

// 💾 Save to file
fs.writeFileSync("merkle-oak_data.json", JSON.stringify(output, null, 2));