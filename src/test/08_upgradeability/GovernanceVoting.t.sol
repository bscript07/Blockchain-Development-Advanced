// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {
    VotingToken,
    VotingLogicV1,
    VotingLogicV2,
    ProposalDoesNotExists,
    AlreadyVoted,
    YouMustOwnTokensToVote,
    ProposalAlreadyExecuted,
    ProposalDidNotPass,
    OnlyProposerCanExecute,
    NotEnoughVotes
} from "@/08_upgradeability/GovernanceVoting.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VotingSystemTest is Test {
    // Main contracts
    VotingToken public votingToken;
    VotingLogicV1 public votingLogic;
    VotingLogicV2 public votingLogicV2;

    // Proxies for upgradeable contracts
    ERC1967Proxy public votingTokenProxy;
    ERC1967Proxy public votingLogicProxy;

    // User addresses
    address public deployer_b = address(0x1);
    address public gogo = address(0x2);
    address public lili = address(0x3);
    address public alex = address(0x4);

    // Events to test
    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteAmount);
    event ProposalExecuted(uint256 indexed proposalId);

    function setUp() public {
        // Setup users with ETH
        vm.deal(deployer_b, 100 ether);
        vm.deal(gogo, 50 ether);
        vm.deal(lili, 50 ether);
        vm.deal(alex, 50 ether);

        // Deploy implementation contracts
        VotingToken tokenImplementation = new VotingToken();
        votingLogic = new VotingLogicV1();
        votingLogicV2 = new VotingLogicV2();

        // Initialize proxies with implementation contracts
        bytes memory tokenData = abi.encodeWithSelector(VotingToken.initialize.selector, deployer_b);

        votingTokenProxy = new ERC1967Proxy(address(tokenImplementation), tokenData);

        // Cast proxy to VotingToken interface
        votingToken = VotingToken(address(votingTokenProxy));

        bytes memory logicData = abi.encodeWithSelector(VotingLogicV1.initialize.selector, address(votingToken));

        votingLogicProxy = new ERC1967Proxy(address(votingLogic), logicData);

        // Cast proxy to VotingLogic interface for current version
        votingLogic = VotingLogicV1(address(votingLogicProxy));

        // Distribute tokens from deployer to users
        vm.startPrank(deployer_b);
        votingToken.transfer(gogo, 10000 * 10 ** 18); // 10000 tokens
        votingToken.transfer(lili, 10000 * 10 ** 18); // 10000 tokens
        votingToken.transfer(alex, 10000 * 10 ** 18); // 10000 tokens
        vm.stopPrank();

        // Delegate votes to self for each user
        vm.prank(gogo);
        votingToken.delegate(gogo);

        vm.prank(lili);
        votingToken.delegate(lili);

        vm.prank(alex);
        votingToken.delegate(alex);

        // Advance block to make sure voting weights are set
        vm.roll(block.number + 1);
    }

    // ==================== VotingToken Tests ====================

    function testTokenInitialSupply() public view {
        assertEq(votingToken.totalSupply(), 1_000_000 * 10 ** 18);
        assertEq(votingToken.balanceOf(deployer_b), 1_000_000 * 10 ** 18 - 30000 * 10 ** 18);
        assertEq(votingToken.balanceOf(gogo), 10000 * 10 ** 18);
        assertEq(votingToken.balanceOf(lili), 10000 * 10 ** 18);
        assertEq(votingToken.balanceOf(alex), 10000 * 10 ** 18);
    }

    function testTokenVotingPower() public view {
        assertEq(votingToken.getVotes(gogo), 10000 * 10 ** 18);
        assertEq(votingToken.getVotes(lili), 10000 * 10 ** 18);
        assertEq(votingToken.getVotes(alex), 10000 * 10 ** 18);
    }

    function testTokenDelegation() public {
        uint256 initialGogoVotes = votingToken.getVotes(gogo);

        vm.prank(lili);
        votingToken.delegate(gogo);

        assertEq(votingToken.getVotes(gogo), initialGogoVotes + 10000 * 10 ** 18);
        assertEq(votingToken.getVotes(lili), 0);
    }

    // // ==================== VotingLogicV1 Tests ====================

    function testCreateProposal() public {
        vm.prank(lili);

        vm.expectEmit(true, false, false, true);
        emit ProposalCreated(0, "Test Proposal");

        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        assertEq(proposalId, 0);
        assertEq(votingLogic.nextProposalId(), 1);

        (uint256 id, address proposer, string memory description,,, bool executed,) = votingLogic.proposals(proposalId);

        assertEq(id, 0);
        assertEq(proposer, lili);
        assertEq(description, "Test Proposal");
        assertEq(executed, false);
    }

    function testVoteOnProposal() public {
        // Create a proposal first
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Vote on the proposal
        vm.prank(gogo);

        // Gogo vote on proposal
        votingLogic.vote(proposalId, true);

        // Check that bob has voted
        assertTrue(votingLogic.hasVoted(gogo, proposalId));
    }

    function testVoteAgainstProposal() public {
        // Create a proposal first
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Vote against the proposal
        vm.prank(gogo);
        votingLogic.vote(proposalId, false);

        // Check proposal state
        (,,, uint256 forVotes, uint256 againstVotes,,) = votingLogic.proposals(proposalId);
        assertEq(forVotes, 0);
        assertEq(againstVotes, 10000 * 10 ** 18);
    }

    function testCannotVoteTwice() public {
        // Create a proposal first
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Vote on the proposal
        vm.prank(gogo);
        votingLogic.vote(proposalId, true);

        // Try to vote again
        vm.prank(gogo);
        vm.expectRevert(AlreadyVoted.selector);
        votingLogic.vote(proposalId, false);
    }

    function testCannotVoteWithoutTokens() public {
        // Create a proposal first
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Try to vote without tokens
        address noTokens = address(0x999);
        vm.prank(noTokens);
        vm.expectRevert(YouMustOwnTokensToVote.selector);
        votingLogic.vote(proposalId, true);
    }

    function testCannotVoteOnNonExistentProposal() public {
        vm.prank(gogo);
        vm.expectRevert(ProposalDoesNotExists.selector);
        votingLogic.vote(8888, true);
    }

    function testExecuteProposalSuccess() public {
        // Create a proposal
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Vote on the proposal
        vm.prank(gogo);
        votingLogic.vote(proposalId, true);

        // Execute the proposal
        vm.prank(lili);
        vm.expectEmit(true, false, false, false);
        emit ProposalExecuted(proposalId);
        votingLogic.executeProposal(proposalId);

        // Check proposal state
        (,,,,, bool executed,) = votingLogic.proposals(proposalId);
        assertTrue(executed);
    }

    function testCannotExecuteIfNotProposer() public {
        // Create a proposal
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Vote on the proposal
        vm.prank(gogo);
        votingLogic.vote(proposalId, true);

        // Try to execute by non-proposer
        vm.prank(gogo);
        vm.expectRevert(OnlyProposerCanExecute.selector);
        votingLogic.executeProposal(proposalId);
    }

    function testCannotExecuteIfNotPassed() public {
        // Create a proposal
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Vote against the proposal
        vm.prank(gogo);
        votingLogic.vote(proposalId, false);

        // Try to execute
        vm.prank(lili);
        vm.expectRevert(ProposalDidNotPass.selector);
        votingLogic.executeProposal(proposalId);
    }

    function testCannotExecuteTwice() public {
        // Create a proposal
        vm.prank(lili);
        uint256 proposalId = votingLogic.createProposal("Test Proposal");

        // Vote for the proposal
        vm.prank(gogo);
        votingLogic.vote(proposalId, true); // gogo vote `for`

        // Execute the proposal
        vm.prank(lili);
        votingLogic.executeProposal(proposalId);

        // Try to execute again
        vm.prank(lili);
        vm.expectRevert(ProposalAlreadyExecuted.selector);
        votingLogic.executeProposal(proposalId);
    }

    // // ==================== VotingLogicV2 Tests ====================

    function testUpgradeToV2() public {
        // Upgrade to V2
        // In a real test, you would use the UUPS or Transparent proxy upgrade mechanism
        // For this test, we'll just simulate the upgrade by creating a new proxy with V2 logic

        bytes memory logicData = abi.encodeWithSelector(VotingLogicV1.initialize.selector, address(votingToken));

        ERC1967Proxy newProxyV2 = new ERC1967Proxy(address(votingLogicV2), logicData);

        VotingLogicV2 votingV2 = VotingLogicV2(address(newProxyV2));

        // Verify quorum function exists and returns expected value
        assertEq(votingV2.quorum(), 1000);
    }

    function testV2ProposalCreation() public {
        // Upgrade to V2
        bytes memory logicData = abi.encodeWithSelector(VotingLogicV1.initialize.selector, address(votingToken));

        ERC1967Proxy newProxyV2 = new ERC1967Proxy(address(votingLogicV2), logicData);

        VotingLogicV2 votingV2 = VotingLogicV2(address(newProxyV2));

        vm.prank(lili);
        uint256 proposalId = votingV2.createProposal("V2 Test Proposal");

        assertEq(proposalId, 0);
        assertEq(votingV2.nextProposalId(), 1);
    }
}
