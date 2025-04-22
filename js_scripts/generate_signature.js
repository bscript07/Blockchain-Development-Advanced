const { Wallet } = require("ethers");
const fs = require("fs");

const John = new Wallet("0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d");

console.log("John wallet address: ", John.address);
console.log("John wallet private key: ", John.privateKey);

const domain = {
    name: "AIAgentShare",
    version: "1",
    chainId: 31337,
    verifyingContract: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
}

const types = {
    BuyApproval: [
        { name: "amount", type: "uint256"},
        { name: "deadline", type: "uint256"},
    ],
}

const value = {
    amount: 10000000000000000000n,
    deadline: 1776870168,
};

John.signTypedData(domain, types, value).then((signature) => {
    console.log("Signature: ", signature);
    fs.writeFileSync("signature.json", JSON.stringify(signature, null, 2));
});
