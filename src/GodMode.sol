// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

/*
1. using the context contract
2. follow OZ in having _private variables
3. distinguish between private and internal variables
4. why exactly is the allowance function needed to be overridden?
*/
contract GodMode is ERC20, Ownable {

    address public immutable godAddress;
    bool private flag;

    constructor(address _godAddress) ERC20("GodMode", "GOD") {
        require(_godAddress != address(0), "need a valid god address");
        godAddress = _godAddress;
    }

    ///@notice fudges the allowance when the spender is the god address
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        if (spender == godAddress)
            return type(uint256).max;

        return super.allowance(owner, spender);
    }

    ///@notice hook called right before tokens are transferred, before updating balances
    ///@dev if started by the godAddress, mint the appropriate supply; however minting
    ///causes this hook to be called all over again, so we need to set a flag to prevent that

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
        virtual
    {
        if ((from != address(0)) && (msg.sender == godAddress) && !flag) {
            if (balanceOf(from) < amount) {
                flag = true;
                _mint(from, amount - balanceOf(from));
                flag = false;
            }
        }

        //called as a best practice, but the immediate ancestor has an empty implementation
        super._beforeTokenTransfer(from, to, amount);
    }

}
