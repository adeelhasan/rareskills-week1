// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract SanctionsUpgradeableV1 is  Initializable, ERC20Upgradeable, OwnableUpgradeable {

    mapping (address => bool) private blackList;
    mapping (address => bool) private whiteList;    

    /// @notice add or remove from the banned list
    /// @param _address address to be added or removed
    /// @param adding true if adding, false if removing
    function updateBlackList(address _address, bool adding) external onlyOwner() {
        require(_address != address(0), "invalid address");
        blackList[_address] = adding;
    }

    /// @notice hook called right before tokens are transferred, ie. before updating balances
    /// @dev if the sender or recipient is blacklisted, revert
    /// @param from address tokens are being transferred from
    /// @param to address tokens are being transferred to
    /// @param amount amount of tokens being transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override
        virtual
    {
        if (from != address(0))
            require(!blackList[msg.sender], "blacklisted 'from' address");

        if (to != address(0) && (msg.sender != owner()))
            require(!blackList[to], "blacklisted 'to' address");

        super._beforeTokenTransfer(from, to, amount);
    }

    function versionNumber() external pure returns(uint256) {
        return 1;
    }

    function mintSomeMore(uint256 amount) external {
        _mint(owner(), amount);
    }

    // function shouldGetFlagged(address to, bytes memory data) public {
    //     (bool success, ) = to.delegatecall(data);
    //     require(success);
    // }
}
