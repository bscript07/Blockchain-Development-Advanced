// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20VotesUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

error ProposalDoesNotExists();
error AlreadyVoted();
error YouMustOwnTokensToVote();
error ProposalAlreadyExecuted();
error ProposalDidNotPass();
error OnlyProposerCanExecute();
error NotEnoughVotes();

event ProposalExecuted(uint256 indexed proposalId);

event ProposalCreated(uint256 indexed proposalId, string description);

event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteAmount);

contract VotingToken is Initializable, ERC20Upgradeable, ERC20VotesUpgradeable {
    address public deployer;

    // Mint 1 million tokens to the deployer at initialization
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

    function initialize(address _deployer) public initializer {
        __ERC20_init("VotingToken", "VOTE");
        __ERC20Votes_init();

        deployer = _deployer;
        _mint(deployer, INITIAL_SUPPLY);
    }

    // Override _update to avoid inheritance conflict
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._update(from, to, value);
    }
}

contract VotingLogicV1 is Initializable {
    // Use math library for numbers
    using Math for uint256;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        uint256 snapshotBlock;
    }

    // Counter for the next proposal ID
    uint256 public nextProposalId;

    // Mapping of proposal IDs to proposals
    mapping(uint256 => Proposal) public proposals;

    // Tracks whether an address has voted on a specific proposal
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    // Reference to the VotingToken contract, set during initialization
    VotingToken public votingToken;

    function initialize(address _votingToken) public initializer {
        votingToken = VotingToken(_votingToken);
    }

    function createProposal(string memory _description) external returns (uint256) {
        uint256 proposalId = nextProposalId;

        // Create new proposal
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            snapshotBlock: block.number - 1
        });

        // Increment proposal ID counter
        nextProposalId++;

        // Emit the proposal creation event
        emit ProposalCreated(proposalId, _description);

        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        // Revert if the proposal does not exist
        if (proposals[proposalId].id != proposalId) revert ProposalDoesNotExists();

        // Revert if the sender has already voted on this proposal
        if (hasVoted[msg.sender][proposalId]) revert AlreadyVoted();

        // Get voter weight
        uint256 voterWeight = votingToken.getPastVotes(msg.sender, proposals[proposalId].snapshotBlock);
        if (voterWeight == 0) revert YouMustOwnTokensToVote();

        // Mark sender as having voted
        hasVoted[msg.sender][proposalId] = true;

        // Add voter weight to 'for' or 'against' votes
        if (support) {
            proposals[proposalId].forVotes += voterWeight;
        } else {
            proposals[proposalId].againstVotes += voterWeight;
        }

        emit Voted(proposalId, msg.sender, support, voterWeight);
    }

    function executeProposal(uint256 proposalId) external virtual {
        // Store proposal in storage
        Proposal storage proposal = proposals[proposalId];

        // Revert if current sender is not the proposer
        if (proposal.proposer != msg.sender) revert OnlyProposerCanExecute();

        // Revert if proposal is executed
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Revert if 'for' votes are less than or equal to 'against' votes
        if (proposal.forVotes <= proposal.againstVotes) revert ProposalDidNotPass();

        // Execute proposal
        proposal.executed = true;

        // Emit proposal execution event
        emit ProposalExecuted(proposalId);
    }
}

contract VotingLogicV2 is VotingLogicV1 {
    function executeProposal(uint256 proposalId) external override {
        // Store proposal in storage
        Proposal storage proposal = proposals[proposalId];

        // Calculate total number of votes
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;

        // Get required quorum (always 1000)
        uint256 quorumRequired = quorum();

        // Revert if total number of votes is less than the quorum
        if (totalVotes < quorumRequired) revert NotEnoughVotes();

        // Revert if current sender is not the proposer
        if (proposal.proposer != msg.sender) revert OnlyProposerCanExecute();

        // Revert if proposal is executed
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Revert if 'for' votes are less than or equal to 'against' votes
        if (proposal.forVotes <= proposal.againstVotes) revert ProposalDidNotPass();

        // Execute proposal
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function quorum() public pure returns (uint256) {
        return 1000;
    }
}
