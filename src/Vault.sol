// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IInterestBearingToken.sol";

contract Vault is AccessControl {
    IInterestBearingToken public token;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setToken(address _token) external onlyRole(MINTER_ROLE) {
        revokeRole(MINTER_ROLE, address(token));
        token = IInterestBearingToken(_token);
        grantRole(MINTER_ROLE, address(token));
    }

    // Users can redeem tokens from the vault
    function redeemFromVault(address to, uint256 amount) external onlyRole(MINTER_ROLE) returns(bool) {
        require(
            token.balanceOf(address(this)) >= amount,
            "Not enough tokens in the vault"
        );
        token.transfer(to, amount);
        return true;
    }
}
