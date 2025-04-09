// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev A simple staking contract with inefficient gas implementation
 */
contract StakingContract {
    IERC20 public stakingToken;
    uint256 public rewardRate = 100;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastUpdateBlock;
        uint256 rewardsAccumulated;
    }

    mapping(address => UserInfo) public userInfo;
    address[] public stakers;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");

        // Update rewards first
        updateReward(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), amount);

        userInfo[msg.sender].stakedAmount += amount;
        stakers.push(msg.sender); // Could add duplicates?

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0");
        require(userInfo[msg.sender].stakedAmount >= amount, "Not enough staked");

        updateReward(msg.sender);

        userInfo[msg.sender].stakedAmount -= amount;
        stakingToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external {
        updateReward(msg.sender);

        uint256 reward = userInfo[msg.sender].rewardsAccumulated;
        if (reward > 0) {
            userInfo[msg.sender].rewardsAccumulated = 0;
            stakingToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function updateReward(address account) public view {
        UserInfo memory user = userInfo[account];

        if (user.stakedAmount > 0) {
            uint256 blocksSinceLastUpdate = block.number - user.lastUpdateBlock;
            uint256 newRewards = (user.stakedAmount * rewardRate * blocksSinceLastUpdate) / 1e18;
            user.rewardsAccumulated += newRewards;
        }

        user.lastUpdateBlock = block.number;
    }

    function updateAllRewards() external view {
        for (uint256 i = 0; i < stakers.length; i++) {
            updateReward(stakers[i]);
        }
    }

    function pendingReward(address account) external view returns (uint256) {
        UserInfo storage user = userInfo[account];

        uint256 pending = user.rewardsAccumulated;

        if (user.stakedAmount > 0) {
            uint256 blocksSinceLastUpdate = block.number - user.lastUpdateBlock;
            uint256 newRewards = (user.stakedAmount * rewardRate * blocksSinceLastUpdate) / 1e18;
            pending += newRewards;
        }

        return pending;
    }
}
