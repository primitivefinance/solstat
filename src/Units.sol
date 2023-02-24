// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error Min();

function abs(int256 input) pure returns (uint256 output) {
    if (input == type(int256).min) revert Min();
    if (input < 0) {
        assembly {
            output := add(not(input), 1)
        }
    } else {
        assembly {
            output := input
        }
    }
}

/// @dev From solmate@v7, changes last `div` to `sdiv`.
function muli(
    int256 x,
    int256 y,
    int256 denominator
) pure returns (int256 z) {
    assembly {
        // Store x * y in z for now.
        z := mul(x, y)

        // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
        if iszero(
            and(iszero(iszero(denominator)), or(iszero(x), eq(sdiv(z, x), y)))
        ) {
            revert(0, 0)
        }

        // Divide z by the denominator.
        z := sdiv(z, denominator)
    }
}

function muliWad(int256 x, int256 y) pure returns (int256 z) {
    z = muli(x, y, 1 ether);
}

function diviWad(int256 x, int256 y) pure returns (int256 z) {
    z = muli(x, 1 ether, y);
}
