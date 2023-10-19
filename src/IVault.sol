// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IVault {
    function withdraw(address to, uint256 amount) external;
    function redeemFromVault(address to, uint256 amount) external returns (bool);
    function setToken(address _token) external;
}
