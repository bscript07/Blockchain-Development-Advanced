const { MerkleTree } = require('merkletreejs')
const { ethers } = require("hardhat");
const fs = require("fs");

const participants = [
    "0x0000000000000000000000000000000000000003",
    "0x0000000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000005"
];

// Dataset with participants hash
const leaves = participants.map((x) => ethers.keccak256(x));

console.log("Leaves: ", leaves);

const tree = new MerkleTree(leaves, ethers.keccak256, {
    duplicateOdd: false,
    sortPairs: true
 });

console.log("Tree: ", tree.toString());

const root = tree.getHexRoot();
console.log("Root: ", root);

// This leaf is a part ot my dataset =>
const leaf = ethers.keccak256("0x0000000000000000000000000000000000000003"); 
const proof = tree.getProof(leaf);

const isProofValid = tree.verify(proof, leaf, root);
console.log("Is proof valid: ", isProofValid);

const proofs = participants.map((x, index) => {
    return {
        address: x,
        proof: tree
        .getProof(leaves[index])
        .map((x) => "0x" + x.data.toString("hex")),
    };
});

const output = {
    root: root,
    proofs: proofs
}

fs.writeFileSync("merkle_data.json", JSON.stringify(output, null, 2));