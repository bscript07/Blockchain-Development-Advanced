// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

/**
 * @notice This contract creates a lottery system with Chainlink VRF for random winner selection
 * @dev Implements Chainlink VRF Version 2 Plus
 */

error NotEnoughETHToEnter();
error RaffleNotOpen();
error CannotRequestRandomWinnerNow();
error TransferFailed();
error UnknownRequestId();

contract Raffle is VRFConsumerBaseV2Plus {

    /* Type of state */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastRequestId;
    
    // Chainlink VRF Variables
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    address private immutable i_vrfCoordinatorV2;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Constructor */
    constructor(
        uint256 entranceFee,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_vrfCoordinatorV2 = vrfCoordinatorV2;
        s_raffleState = RaffleState.OPEN;
    }

    /* External/Public Functions */
    /**
     * @notice Enter the raffle by sending the minimum entrance fee
     * @dev Adds the sender to the players array if requirements are met
     */

    function enterRaffle() external payable {
        // Require minimum entrance fee
        if (msg.value < i_entranceFee) revert NotEnoughETHToEnter();

        // Require raffle is in OPEN state
        if (s_raffleState != RaffleState.OPEN) revert RaffleNotOpen();        
        
        // Store player address in array
        s_players.push(payable(msg.sender));
        
        // Emit RaffleEnter event
        emit RaffleEnter(msg.sender);
    }

    /**
     * @notice Request a random winner
     * @dev Changes state to CALCULATING and requests random number from Chainlink VRF
     */

    function requestRandomWinner() external {
        // Check if can request random winner
        if (!checkCanRequestRandomWinner()) revert CannotRequestRandomWinnerNow();
        
        // Change state to CALCULATING
        s_raffleState = RaffleState.CALCULATING;
        // Request random number from Chainlink VRF
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_gasLane,
            subId: i_subscriptionId,
            requestConfirmations: 3, // Standard confirmations
            callbackGasLimit: i_callbackGasLimit,
            numWords: 1, // We only need one random number
            extraArgs: "" // No extra args needed
        });
        
        uint256 requestId = IVRFCoordinatorV2Plus(i_vrfCoordinatorV2).requestRandomWords(req);
        s_lastRequestId = requestId;
        
        // Emit event when random number is requested
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @notice Callback function used by VRF Coordinator to return random number
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] calldata randomWords) internal override {

        // Check for correct request id
        if (_requestId != s_lastRequestId) revert UnknownRequestId();

        // Select winner
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        
        // Reset raffle's state
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        
        // Transfer prize to winner
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
        
        // Emit event
        emit WinnerPicked(recentWinner);
    }

    /**
     * @notice Check if random winner can be requested
     * @return True if random winner can be requested, false otherwise
     */
    function checkCanRequestRandomWinner() public view returns (bool) {
        return (
            s_raffleState == RaffleState.OPEN &&
            s_players.length > 0
        );
    }

    /* View/Pure Functions */
    /**
     * @notice Get the entrance fee
     * @return The entrance fee for the raffle
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    /**
     * @notice Get the current raffle state
     * @return The current state of the raffle
     */
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    /**
     * @notice Get a player from the players array
     * @param index The index of the player
     * @return The address of the player
     */
    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    /**
     * @notice Get the number of players in the raffle
     * @return The number of players
     */
    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    /**
     * @notice Get the recent winner
     * @return The address of the recent winner
     */
    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
