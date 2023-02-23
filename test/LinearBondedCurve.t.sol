// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokensTestBase.sol";
import "src/LinearBondedCurve.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";


contract LinearBondedCurveTest is TokensTestBase {

    LinearBondedCurve public token;
    
    event ChangeAvailable(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);    


    function setUp() public override {
        super.setUp();
        vm.prank(owner);
        token = new LinearBondedCurve("LBCT", "BCT", 1, 1);

        vm.deal(account1, 1000 ether);
        vm.deal(account2, 1000 ether);
        vm.deal(account3, 1000 ether);
    }


    function testBuyTokens() external {
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.005 ether}("");

        // this would have bonded 50 tokens at the conversion rate of 1 token = 0.0001 ether
        // which implies a supply of 10 as 1/2 of 10 * 10 is 50
        require(token.balanceOf(account1) == 10 * 1e18, "token quantity not as expected");

        (success,) = address(token).call{value: 0.015 ether}("");
        require(token.totalSupply() == 20 * 1e18, "token supply not as expected");
    }


    function testBuyTokensWithPreview() external {
        uint256 expectedMint = token.previewPurchase(0.005 ether);

        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.005 ether}("");

        require(token.balanceOf(account1) == expectedMint * 1e18, "token quantity not as expected");

        //mint some more tokens
        expectedMint += token.previewPurchase(0.015 ether);

        (success,) = address(token).call{value: 0.015 ether}("");
        require(token.totalSupply() == expectedMint * 1e18, "token supply not as expected");
    }


    function testSellTokensWithPreview() external {
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.020 ether}("");
        require(success, "should have succeeded");

        require(token.balanceOf(account1) == 20 * 1e18, "token quantity not as expected");

        uint256 expectedBalanceIncrease = token.previewRedepemtion(10 * 1e18);

        uint256 balanceBefore = account1.balance;
        vm.startPrank(account1);
        token.transferAndCall(address(token), 10 * 1e18);
        token.withdraw();
        vm.stopPrank();
        uint256 balanceAfter = account1.balance;

        require(balanceAfter == balanceBefore + expectedBalanceIncrease, "account1 balance not as expected");
    }


    function testFailBuyTokens() external {
        vm.expectRevert();
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0}("");
        require(!success, "should have failed");
    }


   function testSellTokens() external {
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.02 ether}("");
        require(success, "should have succeeded");

        require(token.balanceOf(account1) == 20 * 1e18, "token quantity not as expected");
        vm.prank(account1);
        token.transfer(account2, 10 * 1e18);
        require(token.balanceOf(account1) == 10 * 1e18, "token quantity not as expected");
        require(token.balanceOf(account2) == 10 * 1e18, "token quantity not as expected");

        uint256 balanceBefore = account2.balance;
        vm.startPrank(account2);
        token.transferAndCall(address(token), 10 * 1e18);
        token.withdraw();
        vm.stopPrank();
        uint256 balanceAfter = account2.balance;
        console.log("balanceBefore: %s", balanceBefore);
        console.log("balanceAfter: %s", balanceAfter);

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
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), account1, 10 * 1e18);
        vm.expectEmit(true, true, true, true);
        emit ChangeAvailable(account1, 0.000001 ether);
        vm.prank(account1);
        (bool success, ) = address(token).call{value: 0.005001 ether}("");
        require(success, "should have succeeded");

        require(token.balanceOf(account1) == 10 * 1e18, "token quantity not as expected");
        vm.startPrank(account1);
        require(token.getBalanceAvailable() == 0.000001 ether, "eth withdrawl balance available not as expected");
        vm.stopPrank();
    }

    function testDifferentSlope() external {
        LinearBondedCurve token2 = new LinearBondedCurve("LBCT", "BCT", 1, 2);
        vm.prank(account1);
        (bool success, ) = address(token2).call{value: 0.005 ether}("");

        // 50 tokens get bonded, but the supply is now different
        // value would be sqrt (2 * 2 * 50) ==> 14.14213562373095
        // price has been floored, but these decimals are there to be used potentially
        require(token2.balanceOf(account1) == 14 * 1e18, "token quantity not as expected");

        (success,) = address(token2).call{value: 0.015 ether}("");
        require(token2.totalSupply() == 28 * 1e18, "token supply not as expected");
    }


}

