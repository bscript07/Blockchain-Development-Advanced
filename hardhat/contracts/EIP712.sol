// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract EIP712Verifier is EIP712 {

    // Define the typehash for the domain separator
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Define the typehash for the struct you're signing
    bytes32 public constant VAULT_APPROVAL_TYPEHASH = keccak256("VaultApproval(address owner,address operator,uint256 value)");

    // Set constructor function with EIP712 with name VaultProtocol and version v1
    constructor() EIP712("VaultProtocol", "v1") {}

    function verifySignature(address owner, address operator, uint256 value, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        // Add new struct hash for verification
        bytes32 structHash = keccak256(abi.encode(VAULT_APPROVAL_TYPEHASH, owner, operator, value));

        // Signed message store on digest
        bytes32 digest = _hashTypedDataV4(structHash);

        // Recover signer
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer != address(0), "Invalid signature!");

        return signer == owner;
    }

}