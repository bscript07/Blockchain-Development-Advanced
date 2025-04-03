// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

contract IOptimizedStakingContract {
    // Create staker data in struct
    struct Staker {
        uint256 stakedAmount;
        uint256 lastUpdateBlock;
        uint256 earnedRewards;
    }

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaim(address indexed user, uint256 reward);
}
