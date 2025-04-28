// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {BaseNFT} from "@/08_upgradeability/FactoryPattern.sol";
import {NFTFactory} from "@/08_upgradeability/FactoryPattern.sol";

contract FactoryPatternTest is Test {
    BaseNFT public baseNft;
    NFTFactory public nftFactory;
    address public ani;

    function setUp() public {
        // 1. Deploy BaseNFT implementation contract
        baseNft = new BaseNFT();
        baseNft.initializerERC721("Cocker Spaniol", "CSL", address(this));

        // 2. Set new user named `ani`
        ani = makeAddr("ani");

        // 3. Deploy the factory contract with the address of the BaseNFT contract
        nftFactory = new NFTFactory(address(baseNft));
    }

    function testCreateNFTCollection() public {
        // 3. Ani creates an NFT collection
        vm.prank(ani); // simulate that the Ani is calling the function
        nftFactory.createNFTCollection("Dogs", "DGS");

        // 4. Verify that the collection was created and is saved in the factory
        address[] memory collections = nftFactory.getCollections(ani);
        assertEq(collections.length, 1, "Ani should have 1 collection");
        assertEq(collections[0].balance, 0, "Collection should have no NFTs initially");
    }

    function testMintNFT() public {
        // 5. Create collection
        vm.prank(ani);
        nftFactory.createNFTCollection("Dogs", "DGS");

        // Get the created collection address
        address[] memory collections = nftFactory.getCollections(ani);
        address nftCollection = collections[0];

        // Mint an NFT
        vm.prank(ani); // Ani is calling mint
        BaseNFT(nftCollection).safeMint(ani);

        // Check that the minted NFT exists
        assertEq(BaseNFT(nftCollection).ownerOf(0), ani, "Ani should own the minted NFT");
    }
}
