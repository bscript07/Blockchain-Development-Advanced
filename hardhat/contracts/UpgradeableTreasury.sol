// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Import from openzepplin-contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// Import from openzepplin-contracts-upgradeability
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error InvalidAmount();
error InvalidOwner();
error NotEnoughAmount();

contract Shibon is ERC20, Ownable {
    constructor() ERC20("Shibon", "SHB") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract TreasuryV1 is Initializable {
    ERC20 public token;
    address public owner;
    mapping(address => uint256) public deposits;

    function initialize(address _token) public initializer {
        ERC20(_token);
        owner = msg.sender;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, InvalidAmount());
        token.transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] += amount;
    }

    function getDeposit(address account) external view returns (uint256) {
        return deposits[account];
    }
}

contract TreasuryV2 is TreasuryV1 {
    function withdraw(address to, uint256 amount) external {
        require(msg.sender == owner, InvalidOwner());
        require(deposits[to] >= amount, NotEnoughAmount());

        deposits[to] -= amount;
        token.transfer(to, amount);
    }
}