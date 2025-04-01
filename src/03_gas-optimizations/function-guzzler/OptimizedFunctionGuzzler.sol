// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

event Transfer(address from, address to, uint256 amount);

error AlreadyRegistered();
error AlreadyExists();
error NotRegistered();
error InsufficientBalance();

contract OptimizedFunctionGuzzler {
    // Concrete mapping usage
    mapping (address user => uint256) private usersData;

    // Concrete array usage
    mapping (uint256 => bool) private values;
    uint256 private valuesCount;
    uint256 private sum;

    function registerUser() external {
        if (_isRegistered(msg.sender)) revert AlreadyRegistered();

         // Set the Least Significant Bit (LSB) to 1 to indicate registration
         usersData[msg.sender] |= 1;
    }

    function deposit(uint256 _amount) external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();

         // Shift amount left by 1 and add to userData while preserving isRegistered bit
         usersData[msg.sender] += _amount << 1;
    }

    function transfer(address _to, uint256 _amount) external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();
        if (!_isRegistered(_to)) revert NotRegistered();

        uint256 senderBalance = balances(msg.sender);
        if (senderBalance < _amount) revert InsufficientBalance();

        usersData[msg.sender] -= _amount;
        usersData[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
    }

    function balances(address _user) public view returns (uint256) {
        return usersData[_user] >> 1;
    }

    function findUser(address _user) public view returns (bool) {
        return _isRegistered(_user);
    }

    function _isRegistered(address _user) private view returns (bool) {
        return (usersData[_user] & 1) == 1;
    }

    function addValue(uint256 _newValue) external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();

        if (values[_newValue]) revert AlreadyExists();

        values[_newValue] = true;
        valuesCount++;
        sum += _newValue;
    }

    function sumValues() external view returns (uint256) {
        return sum;
    }

    function getAverageValue() external view returns (uint256) {
        return valuesCount == 0 ? 0 : sum / valuesCount;
    }
}