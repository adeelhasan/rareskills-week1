// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice courtesy of https://solidity-by-example.org/library/
library Math {
    function sqrt(uint256 y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
    }
}

