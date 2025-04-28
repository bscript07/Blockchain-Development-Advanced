// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

error DelegateCallFailed();

contract Implementation {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(uint256 _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract Proxy {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(address _contract, uint256 _num) external payable {
        (bool ok,) = _contract.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num));
        require(ok, DelegateCallFailed());
    }
}
