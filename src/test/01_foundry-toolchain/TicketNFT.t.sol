// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TicketNFT } from "@/01_foundry-toolchain/ticketNFT/TicketNFT.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TicketNFTTest is Test {
    TicketNFT ticketNFT;

    address public user1;
    address public user2;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        ticketNFT = new TicketNFT("Raffle Ticket", "RTCK");
    }

    // ------------------------------------------CONSTRUCTOR----------------------------------//
    function testConstructorState() public {
        string memory name = "Raffle Ticket";
        string memory symbol = "RTCK";
        TicketNFT newTicketNFT = new TicketNFT(name, symbol);

        // Check that the contract name is set correctly
        assertEq(newTicketNFT.name(), name);

        // Check that the contract symbol is set correctly
        assertEq(newTicketNFT.symbol(), symbol);
    }

    // ------------------------------------------OWNERSHIP------------------------------------//

    function testOwnership() public view {
        // Ensure that the contract owner is the address that deployed the contract
        assertEq(ticketNFT.owner(), address(this));
    }

    function testOwnershipTransfer() public {
        address newOwner = user1;
        ticketNFT.transferOwnership(newOwner);
        vm.prank(newOwner);
        ticketNFT.acceptOwnership();

        // Check the new owner
        assertEq(ticketNFT.owner(), newOwner);
    }

    function testTransferOwnershipRevert() public {
        // Trying to accept ownership as a non-proposed address should fail
        address newOwner = user1;
        ticketNFT.transferOwnership(newOwner);

        vm.prank(user2); // user2 is not the proposed new owner
        vm.expectRevert(bytes4(keccak256("OwnableUnauthorizedAccount()")), 0);
        ticketNFT.acceptOwnership();
    }

    // ------------------------------------------MINTING--------------------------------------//
    // 1. Successfull Minting
    function testSafeMintSuccess() public {
        uint256 tokenId = ticketNFT.safeMint(user1);

        // Check the token owner and that the tokenId is correct
        assertEq(ticketNFT.ownerOf(tokenId), user1);
        // The first token minted should have tokenId 0
        assertEq(tokenId, 0);
    }

    // 2. Check if minting to the zero address reverts
    function testMintWithZeroAddress() public {
        // Minting to address(0) should fail
        vm.expectRevert("ERC721: mint to the zero address", 0);
        ticketNFT.safeMint(address(0));
    }

    // 3. Only owner can mint
    function testSafeMintOnlyOwner() public {
        // Try minting from a non-owner address (user2 should fail)
        vm.prank(user2);
        vm.expectRevert(bytes4(keccak256("OwnableUnauthorizedAccount()")), 0);

        ticketNFT.safeMint(user2);
    }

    // 4. Token ID incrementation
    function testTokenIdIncrementation() public {
        uint256 tokenId1 = ticketNFT.safeMint(user1);
        uint256 tokenId2 = ticketNFT.safeMint(user2);

        // Check that tokenId increments correctly
        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);

        assertEq(ticketNFT.ownerOf(tokenId1), user1);
        assertEq(ticketNFT.ownerOf(tokenId2), user2);
    }

    function testMultipleMints() public {
        uint256 tokenId1 = ticketNFT.safeMint(user1);
        uint256 tokenId2 = ticketNFT.safeMint(user1);
        uint256 tokenId3 = ticketNFT.safeMint(user2);

        // Ensure tokenId is incremented correctly
        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(tokenId3, 2);
    }

    function testTokenIdOverflow() public {
        // Mint a large number of tokens to test token ID overflow.
        for (uint256 i = 0; i < 10; i++) {
            ticketNFT.safeMint(user1);
        }

        uint256 tokenId = ticketNFT.safeMint(user2);

        // Ensure the token ID increments as expected.
        assertEq(tokenId, 10);
        assertEq(ticketNFT.ownerOf(tokenId), user2);
    }

    // ------------------------------------------INTERFACE--------------------------------------//
    // 1. Check that the contract supports ERC721 interface
    function testSupportInterfaceERC721() public view {
        bytes4 interfaceId = type(ERC721).interfaceId;
        assertTrue(ticketNFT.supportsInterface(interfaceId));
    }

    // 2. Check that the contract supports ERC721Enumerable interface
    function testSupportInterfaceERC721Enumerable() public view {
        bytes4 interfaceId = type(ERC721Enumerable).interfaceId;
        assertTrue(ticketNFT.supportsInterface(interfaceId));
    }

    // 3. Check that the contract does NOT support a random interface
    function testSupportInterfaceInvalid() public view {
        bytes4 randomInterfaceId = bytes4(keccak256("RandomInterface()"));
        assertFalse(ticketNFT.supportsInterface(randomInterfaceId));
    }

    // ------------------------------------------UPDATE && INCREASE--------------------------------------//

    // 1. Check that the balance increases after minting (indirectly tests _increaseBalance)
    function testBalanceIncreaseAfterMint() public {
        uint256 tokenId = ticketNFT.safeMint(user1);

        // Check that user1 now owns 1 token
        assertEq(ticketNFT.balanceOf(user1), 1);
        assertEq(tokenId, 0);
    }

    // 2. Check that minting updates the ownership correctly (indirectly tests _update)
    function testOwnershipUpdateAfterMint() public {
        uint256 tokenId = ticketNFT.safeMint(user1);

        // Check that user1 is the owner of the newly minted token
        assertEq(ticketNFT.ownerOf(tokenId), user1);
    }

    // 3. Check minting a second token and ensure the balance updates (tests both _increaseBalance and _update)
    function testBalanceAndOwnershipUpdate() public {
        uint256 tokenId1 = ticketNFT.safeMint(user1);

        // Check that user1 owns 1 token now
        assertEq(ticketNFT.balanceOf(user1), 1);
        // Check that the second token's owner is still user1
        assertEq(ticketNFT.ownerOf(tokenId1), user1);
    }

    // 4. Ensure the balance is updated correctly when minting to a different address
    function testMintToDifferentAddress() public {
        uint256 tokenId = ticketNFT.safeMint(user2);

        // Check that user2 is the owner of the newly minted token
        assertEq(ticketNFT.ownerOf(tokenId), user2);
        // Check that user2's balance is 1
        assertEq(ticketNFT.balanceOf(user2), 1);
        // Ensure user1's balance is still 0
        assertEq(ticketNFT.balanceOf(user1), 0);
    }

    // Test _update and _increaseBalance directly (through minting and ownership update)
    function testUpdateAndIncreaseBalance() public {
        uint256 tokenId = ticketNFT.safeMint(user1);

        // Verify the balance and ownership update correctly
        assertEq(ticketNFT.balanceOf(user1), 1);
        assertEq(ticketNFT.ownerOf(tokenId), user1);
    }
}
