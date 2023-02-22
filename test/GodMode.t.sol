// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokensTestBase.sol";
import "src/GodMode.sol";

contract GodModeTest is TokensTestBase {

    GodMode public token;
    address public godModeAddress;

    function setUp() public override {
        super.setUp();
        godModeAddress = vm.addr(0xABCD);
        vm.startPrank(owner);
        token = new GodMode(godModeAddress);

        // all balances are 0 at the start
        require(token.balanceOf(godModeAddress) == 0);

        vm.stopPrank();
    }

    function testTransferBetweenAccounts() external {
        vm.prank(godModeAddress);
        token.transferFrom(account1, account2, 100);
        require(token.balanceOf(account2) == 100, "unexpected balance");
    }

    function testTransferBetweenThreeAccounts() external {
        vm.prank(godModeAddress);
        token.transferFrom(account3, account2, 2000);
        require(token.balanceOf(account2) == 2000, "unexpected balance");

        vm.prank(account2);
        token.transfer(account3, 1000);
        require(token.balanceOf(account3) == 1000, "unexpected balance");
    }

    function testFailWithoutGodMode() external {
        token.transferFrom(account1, account2, 100);
    }

}