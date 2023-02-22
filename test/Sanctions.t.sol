// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokensTestBase.sol";
import "src/Sanctions.sol";

contract SanctionsTest is TokensTestBase {

    Sanctions public token;

    function setUp() public override {
        super.setUp();
        
        vm.startPrank(owner);
        token = new Sanctions();
        token.transfer(account1, 1000);
        token.transfer(account2, 1000);
        token.transfer(account3, 1000);

        token.updateBlackList(account1, true);
        token.updateBlackList(account2, true);
        vm.stopPrank();
    }

    function testFailSendingFromBlacklist() external {
        vm.prank(account2);
        token.increaseAllowance(account1, 100);

        vm.prank(account1);
        token.transferFrom(account2, account3, 50);
    }

    function testFailReceivingBlacklist() external {
        vm.prank(account3);
        token.transferFrom(account3, account2, 50);
    }

    function testToggleBlacklist() external {
        vm.prank(owner);
        token.updateBlackList(account2, false);

        vm.prank(account3);
        token.transfer(account2, 50);
        require(token.balanceOf(account2) == 1050);
    }

}