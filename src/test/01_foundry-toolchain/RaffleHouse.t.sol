// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {RaffleHouse} from "@/01_foundry-toolchain/raffle-house/RaffleHouse.sol";
import {TicketNFT} from "@/01_foundry-toolchain/ticketNFT/TicketNFT.sol";

import {TicketPriceTooLow,
RaffleAlreadyStarted,
InvalidRaffleEndTime,
InsufficientRaffleDuration,
RaffleDoesNotExist,
RaffleNotStarted,
RaffleEnded,
InvalidTicketPrice,
RaffleNotEnded,
WinnerAlreadyChosen,
WinnerNotChosen,
NotWinner} from "@/01_foundry-toolchain/raffle-house/RaffleHouse.sol";


event WinnerChosen(uint256 indexed raffleId, uint256 winningTicketIndex);
event PrizeClaimed(
        uint256 indexed raffleId,
        address indexed winner,
        uint256 prizeAmount
    );

contract RaffleHouseTest is Test {
    RaffleHouse public raffleHouse;
    TicketNFT public ticketNFT;
    // Set user addresses
    address public user1;
    address public user2;

    function setUp() public {
        // Set up addresses for testing
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

         // Deploy a new instance of RaffleHouse for each test
        raffleHouse = new RaffleHouse();
        ticketNFT = new TicketNFT("Raffle Ticket", "RTC");
    }

    //--------------------------------------RAFFLE CREATION----------------------------------------//

    function testRaffleCreation() public {
        uint256 ticketPrice = 1 ether;
        // 1 hour duration sale
        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = block.timestamp + 2 hours;
        // Name and symbol for raffle
        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

        raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);

        assertEq(raffleHouse.getRaffleCount(), 1);

        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(0);
        assertEq(raffle.ticketPrice, ticketPrice);
        assertEq(raffle.raffleStart, raffleStart);
        assertEq(raffle.raffleEnd, raffleEnd);
        assertEq(raffle.ticketsContract.name(), raffleName);
        assertEq(raffle.ticketsContract.symbol(), raffleSymbol);
    }

    function testRaffleCreationWithZeroTicketPrice() public {
        uint256 ticketPrice = 0; // zero ticket price
        // 1 hour duration sale
        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = block.timestamp + 2 hours;
        // Name and symbol for raffle
        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

        vm.expectRevert(TicketPriceTooLow.selector);
        raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);

    }

    function testCreateRaffleWithInvalidEndTime() public {
        uint256 ticketPrice = 1 ether; // 1 ether ticket price
        
        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = block.timestamp + 30 minutes; // Less than 1 hour
        // Name and symbol for raffle
        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

        vm.expectRevert(InvalidRaffleEndTime.selector);
        raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);
    }

    function testCreateRaffleWithInsufficientDuration() public {
        uint256 ticketPrice = 1 ether;
        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = raffleStart + 30 minutes; // More than start duration
        // Name and symbol for raffle
        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

        vm.expectRevert(InsufficientRaffleDuration.selector);
        raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);
    }

    // ------------------------------------BUYING TICKET--------------------------------------//

    function testBuyTicketRaffleDoesNotExists() public {
        uint256 invalidRaffleId = 1; // Non-existing raffleId

        vm.expectRevert(RaffleDoesNotExist.selector);
        raffleHouse.buyTicket{value: 1 ether}(invalidRaffleId);
    }

    function testBuyTicketRaffleNotStarted() public {
        uint256 ticketPrice = 1 ether;

        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = block.timestamp + 2 hours;
        // Name and symbol for raffle
        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

        raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);

        // Try buying a ticket before the raffle starts
        vm.expectRevert(RaffleNotStarted.selector);
        raffleHouse.buyTicket{value: ticketPrice}(0);
    }

    function testBuyTicketAfterRaffleEnds() public {
        uint256 ticketPrice = 1 ether;
        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = block.timestamp + 2 hours; // 1 hour duration
        // Name and symbol for raffle
        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

        raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);

        // Fast forward time to after the raffle end
        vm.warp(raffleEnd + 1);

        vm.expectRevert(RaffleEnded.selector);
        raffleHouse.buyTicket(0);
    }

    function testBuyTicketWithInsufficientAmount() public {
        uint256 ticketPrice = 1 ether;

        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = block.timestamp + 2 hours;

        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

        raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);

        uint256 insufficientAmount = 0.5 ether; // Send less than required

        // Warp to after the raffle has started to avoid RaffleNotStarted error
        vm.warp(raffleStart + 1 minutes);

        vm.expectRevert(InvalidTicketPrice.selector); // Expect revert due to insufficient amount
        raffleHouse.buyTicket{value: insufficientAmount}(0); // Trying to buy with insufficient amount
}

    // ---------------------------------GET RAFFLE-------------------------------------------//
    function testGetRaffleValid() public {
        uint256 ticketPrice = 1 ether;

        uint256 raffleStart = block.timestamp + 1 hours;
        uint256 raffleEnd = block.timestamp + 2 hours;

        string memory raffleName = "Test Raffle";
        string memory raffleSymbol = "TRF";

    // Create a raffle
    raffleHouse.createRaffle(ticketPrice, raffleStart, raffleEnd, raffleName, raffleSymbol);

    // Retrieve raffle details using valid raffleId (0 in this case)
    RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(0);

    // Check that the returned raffle matches the expected details
    assertEq(raffle.ticketPrice, ticketPrice);
    assertEq(raffle.raffleStart, raffleStart);
    assertEq(raffle.raffleEnd, raffleEnd);
    assertEq(raffle.ticketsContract.name(), raffleName);
    assertEq(raffle.ticketsContract.symbol(), raffleSymbol);
}

    function testGetRaffleInvalidId() public {
       uint256 invalidRaffleId = 1; // This ID does not exist since we only created raffle with ID 0

    // Expect the function to revert with RaffleDoesNotExist error
    vm.expectRevert(RaffleDoesNotExist.selector);
    raffleHouse.getRaffle(invalidRaffleId); // Attempt to retrieve a non-existing raffle
}

   function testGetRaffleMultipleRaffles() public {
        // Create first raffle
    uint256 ticketPrice1 = 1 ether;
    uint256 raffleStart1 = block.timestamp + 1 hours;
    uint256 raffleEnd1 = block.timestamp + 2 hours;
    string memory raffleName1 = "Raffle 1";
    string memory raffleSymbol1 = "R1";

    raffleHouse.createRaffle(ticketPrice1, raffleStart1, raffleEnd1, raffleName1, raffleSymbol1);

        // Create second raffle
    uint256 ticketPrice2 = 2 ether;
    uint256 raffleStart2 = block.timestamp + 2 hours;
    uint256 raffleEnd2 = block.timestamp + 3 hours;
    string memory raffleName2 = "Raffle 2";
    string memory raffleSymbol2 = "R2";

    raffleHouse.createRaffle(ticketPrice2, raffleStart2, raffleEnd2, raffleName2, raffleSymbol2);

        // Retrieve first raffle (ID 0)
    RaffleHouse.Raffle memory raffle1 = raffleHouse.getRaffle(0);
      assertEq(raffle1.ticketPrice, ticketPrice1);
      assertEq(raffle1.raffleStart, raffleStart1);
      assertEq(raffle1.ticketsContract.name(), raffleName1);
      assertEq(raffle1.ticketsContract.symbol(), raffleSymbol1);

        // Retrieve second raffle (ID 1)
    RaffleHouse.Raffle memory raffle2 = raffleHouse.getRaffle(1);
      assertEq(raffle2.ticketPrice, ticketPrice2);
      assertEq(raffle2.raffleStart, raffleStart2);
      assertEq(raffle2.ticketsContract.name(), raffleName2);
      assertEq(raffle2.ticketsContract.symbol(), raffleSymbol2);
   }




    // -----------------------------------WINNER---------------------------------------------//


}