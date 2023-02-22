// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract TokensTestBase is Test {

    address public account1;
    address public account2;
    address public account3;
    address public owner;

    function setUp() public virtual {
        owner = vm.addr(0xAAAA);
        account1 = vm.addr(0xDABC);
        account2 = vm.addr(0xCDAB);
        account3 = vm.addr(0xBCDA);
    }

}