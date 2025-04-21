// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IOptimizedStakingContract} from "./IOptimizedStakingContract.sol";
import {IERC20} from "./IERC20.sol";

event Staked(address indexed user, uint256 amount);
event Withdrawn(address indexed user, uint256 amount);
event RewardClaim(address indexed user, uint256 reward);

error ZeroAmount();
error NotEnoughStaked();

contract OptimizedStakingContract is IOptimizedStakingContract {
    IERC20 public immutable STAKING_TOKEN;
    uint256 public immutable REWARD_RATE;

    mapping(address staker => Staker) public stakers;

    constructor(address _stakingToken, uint256 _rewardRate) {
        STAKING_TOKEN = IERC20(_stakingToken);
        REWARD_RATE = _rewardRate;
    }

    function stake(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        Staker storage staker = stakers[msg.sender];

        STAKING_TOKEN.transferFrom(msg.sender, address(this), amount);
        _updateReward(staker);
        staker.stakedAmount += amount;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        Staker storage staker = stakers[msg.sender];
        if (staker.stakedAmount < amount) revert NotEnoughStaked();

        _updateReward(staker);
        STAKING_TOKEN.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external {
        Staker storage staker = stakers[msg.sender];
        _updateReward(staker);

        uint256 reward = staker.earnedRewards;
        if (reward > 0) {
            staker.earnedRewards = 0;

            STAKING_TOKEN.transfer(msg.sender, reward);

            emit RewardClaim(msg.sender, reward);
        }
    }

    function getPendingReward(address account) external view returns (uint256 pending) {
        Staker storage staker = stakers[account];

        pending = staker.earnedRewards;

        if (staker.stakedAmount > 0) {
            pending += _calculateRewards(staker.stakedAmount, staker.lastUpdateBlock);
        }
    }

    function _updateReward(Staker storage staker) private {
        if (staker.stakedAmount > 0) {
            staker.earnedRewards += _calculateRewards(staker.stakedAmount, staker.lastUpdateBlock);
        }

        staker.lastUpdateBlock = block.number;
    }

    function _calculateRewards(uint256 _stakedAmount, uint256 _lastUpdateBlock) private view returns (uint256) {
        uint256 blocksLastUpdate = block.number - _lastUpdateBlock;
        return (_stakedAmount * REWARD_RATE * blocksLastUpdate) / 1e18;
    }
}
