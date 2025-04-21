const { hashMessage } = require("ethers");

task("sign", "🖊️ Signs and 🔍 verifies a message using EIP-191")
.setAction(async (_, { ethers }) => {

    // 🔐 Get signer (wallet)
    const [signer] = await ethers.getSigners();

    // 📝 Message to sign
    const message = "Hello, EIP191 0x45";

    // 💥 Hash the message (raw keccak256 hash of UTF-8 bytes)
    const hashBytes = ethers.getBytes(
        ethers.keccak256(ethers.toUtf8Bytes(message))
    );

    // ✍️ Sign the hashed message using EIP-191 (personal_sign style)
    const signature = await signer.signMessage(hashBytes);

    // 🧩 Break signature into components (v, r, s)
    const sig = ethers.Signature.from(signature);

    // 🏗️ Deploy EIP191 contract
    const EIP191 = await ethers.getContractFactory("EIP191");
    const eip191 = await EIP191.deploy();
    await eip191.waitForDeployment();

    // 🔎 Call the smart contract's verifySignature function
    const result = await eip191.verifySignature(message, sig.v, sig.r, sig.s);

    // 🧾 Show original and recovered signer addresses
    console.log("🧑 Signer: ", signer.address);
    console.log("🔄 Recovered signer: ", result);

    // 🔁 Double-check off-chain using ethers.recoverAddress (from digest)
    const messageHash = ethers.hashMessage(hashBytes);
    const recoveredAddress = ethers.recoverAddress(messageHash, signature);

    // ✅ Compare both signer and recovered addresses
    console.log("🎯 Signatures match:", signer.address.toLowerCase() === recoveredAddress.toLowerCase());
});

task("sign712", "🖊️ Signs and ✅ verifies a message using EIP-712")
.setAction(async (_, { ethers }) => {

    // 🔐 Get signer (wallet) address
    const [signer] = await ethers.getSigners();

    // 🏗️ Deploy the EIP712Verifier contract
    const eip712ContractFactory = await ethers.getContractFactory("EIP712Verifier");
    const eip712 = await eip712ContractFactory.deploy();
    await eip712.waitForDeployment();

    // 🧭 Get deployed contract address
    const eip712ContractAddress = await eip712.getAddress();

    // 👤 Define operator (who's approved)
    const operator = "0xEfAcFE3e5610bBf6ac5E8aFc170C20b1818C6695";

    // 💸 Set the value (0.5 ether)
    const value = ethers.parseEther("0.5");

    // 🧾 Define domain for EIP-712
    const domain = {
        name: "VaultProtocol",         // 🏛️ Protocol name
        version: "v1",                 // 📦 Version
        chainId: 31337,                // 🧬 Chain ID (local)
        verifyingContract: eip712ContractAddress, // 📜 Contract address
    };

    // 🏗️ Define typed data structure (VaultApproval)
    const types = {
        VaultApproval: [
            { name: "owner", type: "address" },   // 👑 Who owns it
            { name: "operator", type: "address" },// 🛠️ Who can act
            { name: "value", type: "uint256" },   // 💰 How much
        ],
    };

    // 📨 Message to sign
    const messageValue = { owner: signer.address, operator, value };

    // 🖊️ Sign typed structured data
    const signature = await signer.signTypedData(domain, types, messageValue);

    // 📦 Break signature into (v, r, s)
    const sig = ethers.Signature.from(signature);

    console.log("Message value: ", messageValue);
    console.log("Signature: ", signature);
    console.log("Sig: ", sig);

    // 🔍 Verify signature on-chain
    const isValid = await eip712.verifySignature(
        signer.address,
        operator,
        value,
        sig.v,
        sig.r,
        sig.s
    );


    console.log("✅ Signature valid?", isValid); // Should log: true 🟢 if all is well!
});


task("sign2612", "🚀 Signs and sends a gasless approval using EIP-2612")
.setAction(async (_, { ethers }) => {
    // 🔐 Get the signer (token owner)
    const [signer] = await ethers.getSigners();
    const owner = signer.address;

    // 🏗️ Deploy the ERC2612 token contract
    const ERC2612Factory = await ethers.getContractFactory("ERC2612");
    const erc2612 = await ERC2612Factory.deploy();
    await erc2612.waitForDeployment();

    const erc2612Address = await erc2612.getAddress();

    // 🤝 Set spender and approval amount
    const spender = "0xEfAcFE3e5610bBf6ac5E8aFc170C20b1818C6695";

    // 💸 Approve 100 tokens
    const value = ethers.parseEther("333"); 

    // ⏱️ Deadline for signature validity (10 minutes from now)
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    // 🔁 Get current nonce
    const nonce = await erc2612.nonces(owner);

    // 🌐 Get chain ID
    const chainId = 31337;

    // 📦 EIP-712 Domain data
    const domain = {
        name: "Nocoin",
        version: "1",
        chainId,
        verifyingContract: erc2612Address,
    };

    // 📐 Permit type definition
    const types = {
        Permit: [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" },
        ],
    };

    // 📨 Message to be signed
    const message = {
        owner,
        spender,
        value,
        nonce,
        deadline,
    };

    // 🖋️ Sign the typed data (EIP-712)
    const signature = await signer.signTypedData(domain, types, message);
    const sig = ethers.Signature.from(signature);

    console.log("✍️  Signature:", signature);

    // 🔍 Call permit() on the ERC2612 contract to submit signature on-chain
    const tx = await erc2612.permit(owner, spender, value, nonce, deadline, sig.v, sig.r, sig.s);
    await tx.wait();

    // ✅ Check updated allowance
    const allowance = await erc2612.allowance(owner, spender);
    console.log(`✅ Permit success! New allowance: ${ethers.formatEther(allowance)} Nocoin 💰`);
});
