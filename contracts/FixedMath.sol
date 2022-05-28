// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./FixedNumber.sol";

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
    z = muli(x, y, 1e18);
}

function diviWad(int256 x, int256 y) pure returns (int256 z) {
    z = muli(x, 1e18, y);
}

/**
 * @title Fixed Number Math Library.
 * @author alexangelj
 * @dev Math functions for the signed Fixed256x18 type in FixedNumber.sol.
 * @custom:source
 */
library FixedMath {
    using FixedNumber for Fixed256x18;

    uint256 public constant UZERO = 0;
    int256 public constant ZERO = 0;
    uint256 public constant POSITIVE = 0;
    uint256 public constant NEGATIVE = 1;
    int256 public constant MIN_INT = type(int256).min;

    error Min();

    /**
     * @dev If `input` is negative, the `not` opcode is used to invert it and `1` is added to the result.
     * The `unary` operator is equivalent to this operation.
     * Reverts if `input` is the minimum value of the int256 type.
     *
     * @return output `input` as a non-negative (unsigned) fixed point number.
     */
    function abs(Fixed256x18 input)
        internal
        pure
        returns (UFixed256x18 output)
    {
        if (input.eq(MIN_INT)) revert Min();

        if (input.lt(ZERO)) {
            assembly {
                output := add(not(input), 1)
            }
        } else {
            assembly {
                output := input
            }
        }
    }

    function sqrt(Fixed256x18 input, int256 y)
        internal
        pure
        returns (Fixed256x18 output)
    {}

    function exp(Fixed256x18 input)
        internal
        pure
        returns (Fixed256x18 output)
    {}
}
