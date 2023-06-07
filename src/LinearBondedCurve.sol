// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "erc1363-contracts/token/ERC1363/ERC1363.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/math/SafeMath.sol";

import "erc1363-contracts/token/ERC1363/IERC1363.sol";
import "erc1363-contracts/token/ERC1363/IERC1363Receiver.sol";
import "erc1363-contracts/token/ERC1363/IERC1363Spender.sol";

import "./utility/Mathlib.sol";

contract LinearBondedCurve is ERC1363, IERC1363Receiver, Ownable {

    using SafeMath for uint256;

    /// @notice emitted when there is some ETH leftover after minting tokens
    event ChangeAvailable(address indexed user, uint256 amount);

    /// @notice emitted when tokens are received for redemption
    event TokensReceived(address indexed spender, address indexed sender, uint256 amount, bytes data);    

    uint256 internal immutable _slopeNumerator;
    uint256 internal immutable _slopeDenominator;
    uint256 internal constant _pricePerToken = 0.0001 ether; // price for a whole token
    mapping(address => uint256) internal _withdrawlBalances;

    error NotEnoughBalance(uint256 lookingFor, uint256 actual);
    error EthTransferFailed();

    constructor(string memory name, string memory symbol, uint256 slopeNumerator_, uint256 slopeDenominator_) ERC20(name,symbol) {
        _slopeNumerator = slopeNumerator_;
        _slopeDenominator = slopeDenominator_;
    }

    /// @notice for collateral received, mint tokens according to the bonding curve
    /// @dev if there is a remainder, it is added to the withdrawls mapping
    receive() external payable {
        require(msg.value > 0, "No ETH sent");

        uint256 quantityToBeMinted = _calculateSupplyIncrease(msg.value);
        require(quantityToBeMinted > 0, "Not enough ETH sent to mint anything");

        uint256 priorCollateral = _calculatePoolBalance(totalSupply().div(1e18));
        _mint(msg.sender, quantityToBeMinted * 10**decimals());

        uint256 collateralDelta = _calculatePoolBalance(totalSupply().div(1e18)) - priorCollateral;

        uint256 actualCost = collateralDelta.mul(_pricePerToken);
        if (actualCost < msg.value) {
            _withdrawlBalances[msg.sender] += msg.value - actualCost;
            emit ChangeAvailable(msg.sender, msg.value - actualCost);
        }
    }

    /// @notice for these tokens quantity, how much collateral do I get
    /// @dev preview only, just does the calculation
    /// @param amount the amount of tokens to be redeemed, in base units
    function previewRedepemtion(uint256 amount) external view returns (uint256) {
        return _calculateRedemptionValue(amount);
    }

    /// @notice for this collateral amount, how many tokens do I get
    /// @dev preview only, just does the calculation at current supply
    /// @param collateralAmount the amount of collateral to be added
    function previewPurchase(uint256 collateralAmount) external view returns (uint256) {
        return _calculateSupplyIncrease(collateralAmount);
    }

    /// @notice exchange tokens held by msg.sender for collateral
    /// @dev this does not need to transfer to itself first, instead it burns it directly
    /// @param amount the amount of tokens to redeem
    function redeem(uint256 amount) external {
        if (amount > balanceOf(msg.sender)) revert NotEnoughBalance(amount, balanceOf(msg.sender));

        uint256 saleProceedsInEth = _calculateRedemptionValue(amount);
        // any exit tax will be collected here
        _burn(msg.sender, amount);
        _withdrawlBalances[msg.sender] += saleProceedsInEth;
    }

    /// @notice withdraws the available ETH balance for a user
    function withdraw() external {
        uint256 amount = _withdrawlBalances[msg.sender];
        _withdrawlBalances[msg.sender] = 0;
        (bool success, ) = payable (msg.sender).call{value: amount}("");
        if (!success) revert EthTransferFailed();
    }

    /// @notice returns how much can be withdrawn by a user
    function getBalanceAvailable() external view returns (uint256) {
        return _withdrawlBalances[msg.sender];
    }

    /// @notice this is called after native tokens are transferred to this contract
    /// @dev this is called post transfer, ie. balances have already been updated
    /// @param spender the address that initiated the transfer
    /// @param sender the address that sent the tokens
    /// @param amount the amount of tokens sent
    /// @param data any data that was sent with the transfer
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) public override returns (bytes4) {
        require(msg.sender == address(this), "cannot send another token type");

        uint256 saleProceedsInEth = _calculateRedemptionValue(amount);
        _burn(address(this), amount);
        _withdrawlBalances[sender] += saleProceedsInEth;

        emit TokensReceived(spender, sender, amount, data);

        return IERC1363Receiver.onTransferReceived.selector;
    }

    /// @notice by how much would the supply increase for given amount of bonded tokens
    /// @dev convert from eth to quantity to add as area under the curve
    /// @param amount ETH value of collateral to be added in wei
    /// @return the amount of tokens to be minted, in base units
    function _calculateSupplyIncrease(uint256 amount) internal view returns (uint256) {
        uint256 collateralIncreaseInTokens = amount.div(_pricePerToken); //pricing is already in wei
        return Math.sqrt(collateralIncreaseInTokens.mul(2).mul(_slopeDenominator).div(_slopeNumerator) + (totalSupply().div(1e18))**2) - totalSupply().div(1e18);
    }

    /// @notice calculates how much collateral will be returned for a given amount of tokens
    /// @param amount the amount of tokens to sell, in base units
    /// @return the amount of collateral to be returned, in wei
    function _calculateRedemptionValue(uint256 amount) internal view returns (uint256) {
        uint256 saleProceedsInTokens = _calculatePoolBalance(totalSupply().div(1e18)) - _calculatePoolBalance(totalSupply().div(1e18) - amount.div(1e18));
        uint256 saleProceedsInEth = saleProceedsInTokens * _pricePerToken;
        return saleProceedsInEth;
    }

    /// @notice calculates the area under the curve, which are bonded tokens
    /// @dev formular is just for a triangle area : base * height * 1/2 * slope
    /// @param supply the supply to base the calculation on, in whole units
    /// @return result the area under the curve, in whole units
    function _calculatePoolBalance(uint256 supply) internal view returns (uint256 result) {
        uint256 base = supply;
        uint256 height = base.mul(_slopeNumerator).div(_slopeDenominator);
        result = base.mul(height).div(2);
    }

}


contract LinearBondedCurveEchidnaTest is LinearBondedCurve {
    constructor() LinearBondedCurve("ECHD", "ECH", 1, 1) {}
    function echidna_test_reserve() external view returns (bool result) {
        return address(this).balance >= _pricePerToken * balanceOf(address(this));
    }
}