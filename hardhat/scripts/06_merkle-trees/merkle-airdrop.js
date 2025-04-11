const { MerkleTree } = require('merkletreejs')
const { ethers } = require("hardhat");
const fs = require("fs");

const recipients = [
    {
        address: "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        amount: ethers.parseEther("100"),
    },
    {
        address: "0x0000000000000000000000000000000000000004",
        amount: ethers.parseEther("200"),
    },
    {
        address: "0x0000000000000000000000000000000000000005",
        amount: ethers.parseEther("300"),
    },
    {
        address: "0x0000000000000000000000000000000000000006",
        amount: ethers.parseEther("400"),
    },
    {
        address: "0x0000000000000000000000000000000000000007",
        amount: ethers.parseEther("500"),
    },
];

const leaves = recipients.map((x) => ethers.keccak256(ethers.solidityPacked(["address", "uint256"], [x.address, x.amount])));

const tree = new MerkleTree(leaves, ethers.keccak256, {
    sortPairs: true,
});

const root = tree.getHexRoot();

const proofs = recipients.map((x, index) => {
    return {
        address: x.address,
        amount: x.amount.toString(),
        proof: tree
        .getProof(leaves[index])
        .map((x) => "0x" + x.data.toString("hex")),
    };
});

const output = {
    root: root,
    proofs: proofs
}

fs.writeFileSync("merkle_data_airdrop.json", JSON.stringify(output, null, 2));

