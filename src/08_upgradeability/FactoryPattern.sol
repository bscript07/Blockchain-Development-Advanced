// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract BaseNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    uint256 private _nextTokenId;

    function initializerERC721(string memory name, string memory symbol, address initialOwner) external initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
    }

    function safeMint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }
}

contract NFTFactory {
    address public immutable implementation;
    mapping(address => address[]) public collections;

    // Store data for off-chain operations
    event CollectionCreated(address indexed ani, address collection);

    // Set implementation address when deploy
    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createNFTCollection(string memory name, string memory symbol) external {
        // Clone the implementation contract using ERC-1167 standart
        address clone = Clones.clone(implementation);

        // Create NFT with new cloned contract
        BaseNFT(clone).initializerERC721(name, symbol, msg.sender);

        // Save every clone collection in mapping array
        collections[msg.sender].push(clone);

        // Emit Ani creation collection
        emit CollectionCreated(msg.sender, clone);
    }

    function getCollections(address ani) external view returns (address[] memory) {
        return collections[ani];
    }
}
