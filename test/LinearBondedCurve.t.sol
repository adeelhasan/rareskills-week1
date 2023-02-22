// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokensTestBase.sol";
import "src/LinearBondedCurve.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";


contract LinearBondedCurveTest2 is TokensTestBase {

    LinearBondedCurve public token;

    function setUp() public override {
        super.setUp();
        vm.prank(owner);
        token = new LinearBondedCurve("LBCT", "BCT", 1, 1);

        vm.deal(account1, 10 ether);
        vm.deal(account2, 10 ether);
        vm.deal(account3, 10 ether);
    }

    function testBuyTokens() external {
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.005 ether}("");

        require(token.balanceOf(account1) == 10, "token quantity not as expected");

        (success,) = address(token).call{value: 0.015 ether}("");
        require(token.totalSupply() == 20, "token supply not as expected");
    }

    function testFailBuyTokens() external {
        vm.expectRevert();
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0}("");
        require(!success, "should have failed");
    }

    function testSellTokens() external {
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.020 ether}("");
        require(success, "should have succeeded");

        require(token.balanceOf(account1) == 20, "token quantity not as expected");
        vm.prank(account1);
        token.transfer(account2, 10);
        require(token.balanceOf(account1) == 10, "token quantity not as expected");
        require(token.balanceOf(account2) == 10, "token quantity not as expected");

        uint256 balanceBefore = account2.balance;
        vm.startPrank(account2);
        token.transferAndCall(address(token), 10);
        token.withdraw();
        vm.stopPrank();
        uint256 balanceAfter = account2.balance;

        require(token.balanceOf(account2) == 0, "token quantity not as expected");
        require(balanceAfter > balanceBefore, "account2 balance didnt increase");
    }

    function testCannotMintWithTooFewFunds() external {
        vm.prank(account1);
        vm.expectRevert("Not enough ETH sent to mint anything");
        (bool success, ) = address(token).call{value: 1000}("");
        require(success, "should have failed");
    }

    function testChangeAvailable() external {
        //vm.expectEmits(token, "ChangeAvailable"); /// TBD
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.005001 ether}("");
        require(success, "should have succeeded");

        require(token.balanceOf(account1) == 10, "token quantity not as expected");
        vm.startPrank(account1);
        require(token.getBalanceAvailable() == 0.000001 ether, "eth withdrawl balance available not as expected");
        vm.stopPrank();
    }

    function testBuyTokensWithPreview() external {
        uint256 expectedMint = token.previewPurchase(0.005 ether);

        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.005 ether}("");

        require(token.balanceOf(account1) == expectedMint, "token quantity not as expected");

        expectedMint = expectedMint + token.previewPurchase(0.015 ether);

        (success,) = address(token).call{value: 0.015 ether}("");
        require(token.totalSupply() == expectedMint, "token supply not as expected");
    }

    function testSellTokensWithPreview() external {
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.020 ether}("");
        require(success, "should have succeeded");

        require(token.balanceOf(account1) == 20, "token quantity not as expected");

        uint256 expectedBalanceIncrease = token.previewRedepemtion(10);

        uint256 balanceBefore = account1.balance;
        vm.startPrank(account1);
        token.transferAndCall(address(token), 10);
        token.withdraw();
        vm.stopPrank();
        uint256 balanceAfter = account1.balance;

        require(balanceAfter == balanceBefore + expectedBalanceIncrease, "account1 balance not as expected");
    }

}

