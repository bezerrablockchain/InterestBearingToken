// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {InterestBearingToken} from "../src/InterestBearingToken.sol";
import {Vault} from "../src/Vault.sol";

contract InterestBearingTokenTest is Test {
    InterestBearingToken public interestBearingToken;
    Vault public vault;

    address public admin = address(1);
    address public user01 = address(10);
    address public user02 = address(20);

    uint256 internal constant FULL_DECIMALS = 10 ** 18;
    uint256 internal initialTimestamp;

    function setUp() public {
        uint256 initialVaultBalance = 10_000 * FULL_DECIMALS;
        vm.startPrank(admin);

        vault = new Vault();
        interestBearingToken = new InterestBearingToken(address(vault));

        vault.setToken(address(interestBearingToken));
        interestBearingToken.mint(address(vault), initialVaultBalance);

        vm.stopPrank();
        initialTimestamp = block.timestamp;
    }

    function test_mintToUser() public {
        vm.startPrank(admin);

        uint256 tokensAmount = 100 * FULL_DECIMALS;
        interestBearingToken.mint(user01, tokensAmount);
        assertEq(interestBearingToken.balanceOf(user01), tokensAmount);

        vm.stopPrank();
    }

    function test_InterestRate() public {
        vm.startPrank(admin);

        interestBearingToken.setInterestRate(100);
        assertEq(interestBearingToken.interestRateBPS(), 100);

        vm.stopPrank();
    }

    function test_balanceOfWithInterestSameTimestamp() public {
        vm.startPrank(admin);

        uint256 tokensAmount = 100 * FULL_DECIMALS;
        interestBearingToken.mint(user01, tokensAmount);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).principal, tokensAmount);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).interest, 0);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).total, tokensAmount);

        interestBearingToken.setInterestRate(100);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).principal, tokensAmount);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).interest, 0);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).total, tokensAmount);

        vm.stopPrank();
    }

    function test_balanceOfWithInterest() public {
        vm.startPrank(admin);
        uint256 oneYearLater = initialTimestamp + 365 days;
        uint256 tokensAmount = 100 * FULL_DECIMALS;
        uint256 oneYearInterest = (tokensAmount * 100) / 10000;

        interestBearingToken.mint(user01, tokensAmount);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).principal, tokensAmount);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).interest, 0);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).total, tokensAmount);

        interestBearingToken.setInterestRate(100); // 1% per year
        vm.warp(oneYearLater);

        assertEq(interestBearingToken.balanceOfWithInterest(user01).principal, tokensAmount);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).interest, oneYearInterest);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).total, tokensAmount + oneYearInterest);

        vm.stopPrank();
    }

    function test_balanceOfWithInterestTwoDeposits() public {
        vm.startPrank(admin);
        uint256 oneYear = 365 days;
        uint256 sixMonths = 182 days + 12 hours;

        uint256 tokensAmount = 100 * FULL_DECIMALS;
        uint256 oneYearInterest = (((tokensAmount * 2 * 100) / 10000) * 75) / 100; // 75% of 2 years interest

        interestBearingToken.mint(user01, tokensAmount); //1st mint

        assertEq(interestBearingToken.balanceOfWithInterest(user01).principal, tokensAmount);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).interest, 0);
        assertEq(interestBearingToken.balanceOfWithInterest(user01).total, tokensAmount);

        interestBearingToken.setInterestRate(100); // 1% per year

        vm.warp(sixMonths + initialTimestamp); //half year later

        interestBearingToken.mint(user01, tokensAmount); //2nd mint

        vm.warp(oneYear + initialTimestamp);

        assertEq(interestBearingToken.balanceOfWithInterest(user01).principal, tokensAmount * 2, "1");
        assertEq(interestBearingToken.balanceOfWithInterest(user01).interest, oneYearInterest, "2");
        assertEq(interestBearingToken.balanceOfWithInterest(user01).total, (tokensAmount * 2) + oneYearInterest, "3");

        vm.stopPrank();
    }

    function test_withdrawInterest() public {
        vm.startPrank(admin);
        uint256 oneYear = 365 days;
        uint256 tokensAmount = 100 * FULL_DECIMALS;

        interestBearingToken.mint(user01, tokensAmount);
        interestBearingToken.setInterestRate(100); // 1% per year

        vm.warp(oneYear + initialTimestamp); //one year later

        vm.stopPrank();

        vm.startPrank(user01);
        uint256 interest = interestBearingToken.accumulatedInterest(user01);

        interestBearingToken.withdrawInterest();
        vm.stopPrank();

        assertEq(interestBearingToken.balanceOf(user01), tokensAmount + interest);
    }

    function test_withdrawInterestAfterTransfer() public {
        vm.startPrank(admin);

        uint256 oneYear = 365 days;
        uint256 sixMonths = 182 days + 12 hours;
        uint256 tokensAmount = 100 * FULL_DECIMALS;

        interestBearingToken.mint(user01, tokensAmount);
        interestBearingToken.setInterestRate(100); // 1% per year

        vm.stopPrank();

        vm.warp(sixMonths + initialTimestamp); //six months later

        vm.startPrank(user01);

        interestBearingToken.transfer(user02, tokensAmount / 2); // transfer half of the tokens

        vm.warp(oneYear + initialTimestamp); //one year later

        uint256 balanceUser01 = interestBearingToken.balanceOf(user01);
        uint256 balanceUser02 = interestBearingToken.balanceOf(user02);
        uint256 interestUser01 = interestBearingToken.accumulatedInterest(user01);
        uint256 interestUser02 = interestBearingToken.accumulatedInterest(user02);

        uint256 calculatedInterestUser01 = ((((tokensAmount) * 100) / 10000) * 50) / 100; // 50% of 1 year interest
        uint256 calculatedInterestUser02 = ((((tokensAmount) * 100) / 10000) * 25) / 100; // 25% of 1 year interest
        
        assertEq(interestUser01, calculatedInterestUser01);
        assertEq(interestUser02, calculatedInterestUser02);
        
        vm.stopPrank();

        vm.prank(user01);
        interestBearingToken.withdrawInterest();

        vm.prank(user02);
        interestBearingToken.withdrawInterest();

        assertEq(interestBearingToken.balanceOf(user01), balanceUser01 + calculatedInterestUser01);
        assertEq(interestBearingToken.balanceOf(user02), balanceUser02 + calculatedInterestUser02);

    }

    function test_balanceOfWithInterestAfterBurn() public {
        vm.startPrank(admin);

        uint256 oneYear = 365 days;
        uint256 tokensAmount = 100 * FULL_DECIMALS;

        interestBearingToken.mint(user01, tokensAmount);
        interestBearingToken.setInterestRate(100); // 1% per year

        vm.warp(oneYear + initialTimestamp); //one year later

        vm.stopPrank();

        vm.startPrank(user01);

        uint256 interest = interestBearingToken.accumulatedInterest(user01);
        uint256 balance = interestBearingToken.balanceOf(user01);

        interestBearingToken.burn(tokensAmount / 2);

        vm.stopPrank();

        assertEq(interestBearingToken.balanceOf(user01), (tokensAmount / 2));
        assertEq(interestBearingToken.balanceOfWithInterest(user01).principal, balance - (tokensAmount / 2));
        assertEq(interestBearingToken.balanceOfWithInterest(user01).interest, (interest / 2));
        assertEq(interestBearingToken.balanceOfWithInterest(user01).total, balance - (tokensAmount / 2) + (interest / 2));
    }

    function test_balanceOfWithInterestWithDifferentAPYs() public {
        vm.startPrank(admin);

        uint256 oneYear = 365 days;
        uint256 tokensAmount = 100 * FULL_DECIMALS;
        uint256 expectedHalfPercentInterest = (tokensAmount * 50) / 10000;
        uint256 expectedOnePercentInterest = (tokensAmount * 100) / 10000;
        uint256 expectedTenPercentInterest = (tokensAmount * 1000) / 10000;
        uint256 expectedOneHunPercentInterest = (tokensAmount * 10000) / 10000;

        interestBearingToken.mint(user01, tokensAmount);
        
        vm.warp(oneYear + initialTimestamp); //one year later
        
        interestBearingToken.setInterestRate(50); // 1% per year
        assertEq(expectedHalfPercentInterest, interestBearingToken.accumulatedInterest(user01));

        interestBearingToken.setInterestRate(100); // 1% per year
        assertEq(expectedOnePercentInterest, interestBearingToken.accumulatedInterest(user01));

        interestBearingToken.setInterestRate(1000); // 10% per year
        assertEq(expectedTenPercentInterest, interestBearingToken.accumulatedInterest(user01));

        interestBearingToken.setInterestRate(10000); // 100% per year
        assertEq(expectedOneHunPercentInterest, interestBearingToken.accumulatedInterest(user01));

        vm.stopPrank();

    }
}
