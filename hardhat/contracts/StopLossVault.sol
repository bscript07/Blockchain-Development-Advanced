// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

struct Vault { 
    address owner; // vault owner
    uint256 amount; // amount ETH in vault
    uint256 stopLossPrice; // in USD, 8 decimals 
    bool active; // is active  
}

error TransferFailed();
error VaultNotActive();
error NotVaultOwner();
error InsufficientETH();
error PriceIsAboveStopLoss();

contract StopLoss is ReentrancyGuard {
    // Chainlink Price Feed for ETH/USD

        AggregatorV3Interface internal constant DATA_FEED = AggregatorV3Interface(
        0x694AA1769357215DE4FAC081bf1f309aDC325306
    );

    // Store all vaults
    mapping(uint256 => Vault) public vaults;
    uint256 private vaultIdCounter;

    event VaultCreated(address indexed user, uint256 deposit, uint256 stopLossPrice);
    event Deposited(uint256 indexed vaultId, address indexed user, uint256 amount);
    event Withdrawn(uint256 indexed vaultId, address indexed user, uint256 amount);

    // Stop-loss price $1800
    uint256 public constant STOP_LOSS_PRICE = 1800 * 10 ** 8; // 8 decimals

    function createVault() external payable {
        if (msg.value < 0) revert InsufficientETH();

        uint256 vaultId = vaultIdCounter++;
        vaults[vaultId] = Vault({
            owner: msg.sender,
            amount: msg.value,
            stopLossPrice: STOP_LOSS_PRICE,
            active: true
        });

        emit VaultCreated(msg.sender, msg.value, STOP_LOSS_PRICE);
    }

    function deposit(uint256 vaultId) external payable nonReentrant {
        Vault storage userVault = vaults[vaultId];

        if (userVault.owner != msg.sender) revert NotVaultOwner();
        if (!userVault.active) revert VaultNotActive();

        userVault.amount += msg.value;

        emit Deposited(vaultId, msg.sender, msg.value);
    }

    function withdraw(uint256 vaultId) external nonReentrant {
        Vault storage userVault = vaults[vaultId];

        if (userVault.owner != msg.sender) revert NotVaultOwner();
        if (!userVault.active) revert VaultNotActive();

        // Current price ETH/USD
        int256 currentPrice = getLatestPrice();
        if (currentPrice > int256(userVault.stopLossPrice)) revert PriceIsAboveStopLoss();

        uint256 amountToWithdraw = userVault.amount;
        userVault.amount = 0;
        userVault.active = false;

        (bool ok, ) = msg.sender.call{value: amountToWithdraw}("");
        if (!ok) revert TransferFailed();

        emit Withdrawn(vaultId, msg.sender, amountToWithdraw);
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

    function getVault(uint256 vaultId) external view returns (Vault memory) {
        return vaults[vaultId];
    }

    function getVaultBalance(uint256 vaultId) external view returns (uint256) {
        return vaults[vaultId].amount;
    }
}