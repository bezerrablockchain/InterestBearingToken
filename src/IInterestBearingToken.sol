// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IInterestBearingToken {
    // Function signatures
    function setInterestRate(uint256 rateBPS) external;
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function transfer(address to, uint256 value) external returns (bool);

    // Event signatures
    event InterestRateChanged(uint256 newRateBPS);
    event DepositAdded(address indexed account, uint256 amount, uint256 timestamp);
    event DepositUpdated(address indexed account, uint256 index, uint256 newAmount);
}
