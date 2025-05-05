// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Direction of the user's bet – either Up or Down
enum Direction {
    Up,
    Down
}

/// @notice Round represents a prediction game session with specific time and price data
struct Round {
    uint256 lockTime;       // Timestamp when betting closes
    uint256 endTime;        // Timestamp when round ends and price is resolved
    uint256 startPrice;     // Price at lock time
    uint256 endPrice;       // Price at round end
    uint totalUp;           // Total ETH bet on Up
    uint totalDown;         // Total ETH bet on Down
    bool resolved;          // Has the round been resolved
}

/// @notice A user's individual bet for a given round
struct Bet {
    Direction direction;    // Up or Down
    uint256 bet;            // Amount in wei
}

// Custom errors for gas efficiency and clarity
error NotOwner();
error BetLocked();
error AlreadyBet();
error AlreadyClaimed();
error TooLateToStart();
error PreviousNotResolved();
error WaitingNotFinished();
error SomethingWentWrong();
error BetTooLow();
error RoundNotResolved();

/// @title Price Prediction Game
/// @notice A smart contract that lets users bet ETH on whether the ETH/USD price will go up or down
/// @dev Uses Chainlink Data Feeds to resolve outcomes. Each round is 5 minutes long.
contract PricePrediction is ReentrancyGuard {
    AggregatorV3Interface internal constant DATA_FEED = AggregatorV3Interface(
        0x694AA1769357215DE4FAC081bf1f309aDC325306
    );

    address public owner;
    uint256 public currentRoundId;

    mapping (uint256 => Round) public rounds;
    mapping (uint256 => mapping (address => Bet)) public bets;
    mapping (uint256 => mapping (address => bool)) public rewardsClaimed;

    /// @dev Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Initializes contract with deployer as owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Starts a new prediction round
    /// @dev Can only be called by owner. Must be within first 2 minutes of a 5-minute cycle.
    function startRound() external onlyOwner {
        uint256 secondsAfterHour = block.timestamp % 5 minutes;

        if (secondsAfterHour > 2 minutes) revert TooLateToStart();
        if (!rounds[currentRoundId].resolved) revert PreviousNotResolved();

        currentRoundId++;

        rounds[currentRoundId] = Round({
            lockTime: block.timestamp + 2 minutes,
            endTime: block.timestamp + (5 minutes - secondsAfterHour),
            startPrice: uint256(getLatestPrice()),
            endPrice: 0,
            totalUp: 0,
            totalDown: 0,
            resolved: false
        });
    }

    /// @notice Place a bet on the current round
    /// @param _direction Direction.Up or Direction.Down
    /// @dev Cannot bet after lock time. Minimum bet is 0.001 ETH.
    function bet(Direction _direction) external payable {
        Round storage round = rounds[currentRoundId];
        
        if (msg.value < 0.001 ether) revert BetTooLow();
        if (block.timestamp >= round.lockTime) revert BetLocked();
        if (bets[currentRoundId][msg.sender].bet != 0) revert AlreadyBet();

        bets[currentRoundId][msg.sender] = Bet(_direction, msg.value);

        if (_direction == Direction.Up) {
            round.totalUp += msg.value;
        } else {
            round.totalDown += msg.value;
        }
    }

    /// @notice Resolves the current round's end price
    /// @dev Can only be called by owner after round end time + buffer
    function setWinner() external onlyOwner {
        Round storage round = rounds[currentRoundId];

        if (block.timestamp < round.endTime) revert WaitingNotFinished();

        // Optional buffer: only fetch price if we are past the resolution window
        if (block.timestamp > round.endTime + 2 minutes) {
            round.endPrice = uint256(getLatestPrice());
        }

        round.resolved = true;
    }

    /// @notice Claims reward for a finished round if user guessed correctly
    /// @param roundToClaim The round ID to claim
    /// @dev Uses call() to send ETH. Protected with nonReentrant.
    function claimReward(uint256 roundToClaim) external nonReentrant {
        Round storage round = rounds[roundToClaim];
        Bet memory userBet = bets[roundToClaim][msg.sender];

        if (!round.resolved) revert RoundNotResolved();
        if (rewardsClaimed[roundToClaim][msg.sender]) revert AlreadyClaimed(); 

        uint256 reward;
        uint256 totalBet = round.totalUp + round.totalDown;

        // Case: No movement or price is not set → refund
        if (round.endPrice == 0 || round.startPrice == round.endPrice) {
            reward = userBet.bet;
        } 
        // Winning condition: Price went down and user bet Down
        else if (
            round.startPrice > round.endPrice &&
            userBet.direction == Direction.Down &&
            round.totalDown != 0
        ) {
            reward = (userBet.bet * totalBet) / round.totalDown;
        } 
        // Winning condition: Price went up and user bet Up
        else if (
            round.startPrice < round.endPrice &&
            userBet.direction == Direction.Up &&
            round.totalUp != 0
        ) {
            reward = (userBet.bet * totalBet) / round.totalUp;
        }

        rewardsClaimed[roundToClaim][msg.sender] = true;

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        if (!success) revert SomethingWentWrong();
    }

    /// @notice Returns a user's bet for a specific round
    /// @param roundId Round to query
    /// @param user Address of the user
    function getUserBet(uint256 roundId, address user) external view returns (Bet memory) {
        return bets[roundId][user];
    }

    /// @notice Fetches latest ETH/USD price from Chainlink
    function getLatestPrice() public view returns (int) {
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = DATA_FEED.latestRoundData();
        return answer;
    }
}
