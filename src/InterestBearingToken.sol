// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVault.sol";

contract InterestBearingToken2 is ERC20, Ownable {
    uint256 public interestRateBPS = 0;
    IVault public vault;

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    struct Balance {
        uint256 principal;
        uint256 interest;
        uint256 total;
    }

    mapping(address => Deposit[]) public deposits;

    // Event declarations
    event InterestRateChanged(uint256 newRateBPS);
    event DepositAdded(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );
    event DepositUpdated(
        address indexed account,
        uint256 index,
        uint256 newAmount
    );

    constructor(address _vault)
        ERC20("InterestBearingToken", "IBT")
        Ownable(msg.sender)
    {
        vault = IVault(_vault);

        // vault.setToken(address(this));
        // _mint(address(vault), 1000000 * (10  ** 18)); //Initial rewardBalance
    }

    function mint(address account, uint256 value) external onlyOwner{
        _mint(account, value);
    }

    function setInterestRate(uint256 rateBPS) external onlyOwner {
        interestRateBPS = rateBPS;
        emit InterestRateChanged(rateBPS);
    }

    function balanceOfWithInterest(address account)
        public
        view
        returns (Balance memory)
    {
        uint256 principalBalance = super.balanceOf(account);
        uint256 total = principalBalance + accumulatedInterest(account);

        return Balance(principalBalance, accumulatedInterest(account), total);
    }

    function accumulatedInterest(address account)
        public
        view
        returns (uint256)
    {
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < deposits[account].length; i++) {
            uint256 elapsedTime = block.timestamp -
                deposits[account][i].timestamp;
            uint256 interest = (((deposits[account][i].amount *
                interestRateBPS) / 10000) * elapsedTime) / 365 days;
            totalInterest += interest;
        }
        return totalInterest;
    }

    function withdrawInterest() external {
        uint256 interest = accumulatedInterest(msg.sender);
        require(interest > 0, "No interest to withdraw");

        // Reset timestamp of all deposits for the user to current time after withdrawing interest.
        for (uint256 i = 0; i < deposits[msg.sender].length; i++) {
            deposits[msg.sender][i].timestamp = block.timestamp;
        }

        bool ret = vault.redeemFromVault(msg.sender, interest);
        if (ret) {
            deposits[msg.sender].push(Deposit(interest, block.timestamp));
        }
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            // Update deposits for the sender
            uint256 remaining = amount;
            for (
                uint256 i = 0;
                i < deposits[from].length && remaining > 0;
                i++
            ) {
                if (deposits[from][i].amount <= remaining) {
                    remaining -= deposits[from][i].amount;
                    // Remove deposit by replacing it with the last element
                    if (i != deposits[from].length - 1) {
                        deposits[from][i] = deposits[from][
                            deposits[from].length - 1
                        ];
                    }
                    deposits[from].pop();
                    i--; // Recheck the current index, as it now contains the last element.
                } else {
                    deposits[from][i].amount -= remaining;
                    emit DepositUpdated(from, i, deposits[from][i].amount);
                    remaining = 0;
                }
            }
        }

        if (to != address(0)) {
            // Add a new deposit for the recipient
            deposits[to].push(Deposit(amount, block.timestamp));
            emit DepositAdded(to, amount, block.timestamp);
        }

        super._update(from, to, amount);
    }
}