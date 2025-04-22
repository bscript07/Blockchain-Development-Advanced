// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error ExceedsInitialSupply();
error ExceedsMaxSupply();
error InvalidSignature();
error AuthorizationAlreadyUsed();
error AuthorizationNotValid();
error AuthorizationExpired();

contract ERC2612 is ERC20, ERC20Permit, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10 ** 18;

    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = keccak256(
        "TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
    );

    mapping(bytes32 => bool) public authorizationUsed;

    constructor(uint256 _initialSupply) ERC20("ERC20 Token", "ERCT") ERC20Permit("ERC20 Token") Ownable(msg.sender) {
        if (_initialSupply > MAX_SUPPLY) {
            revert ExceedsInitialSupply();
        }
        _mint(msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp < validAfter) revert AuthorizationNotValid();
        if (block.timestamp > validBefore) revert AuthorizationExpired();
        if (authorizationUsed[nonce]) revert AuthorizationAlreadyUsed();

        bytes32 structHash =
            keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != from) revert InvalidSignature();

        authorizationUsed[nonce] = true;
        _transfer(from, to, value);
    }

    // 👇 Helper function for domain separator from EIP712
    function getAuthorizationTypedDataHash(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce
    ) public view returns (bytes32) {
        bytes32 structHash =
            keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));

        return _hashTypedDataV4(structHash);
    }
}
