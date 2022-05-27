// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

type UFixed256x18 is uint256; // 60 digits . 18 digits
type Fixed256x18 is int256; // 1 digit sign 59 digits . 18 digits

/**
 * @title Fixed Number Library.
 * @author alexangej
 *
 * @notice A 256-bit wide signed integer with 18 decimals (decimals after binary point position) of precision.
 * Fixed point numbers are useful because they inherit native arithmetic available in the evm,
 * while being able to represent a fractional part in the least significant digits (18 in this case).
 *
 * @dev All operators are **unsafe**, because they do not have over/under-flow checks.
 * Utilizes solc-0.8.8 user defined custom types.
 *
 * @custom:source https://blog.soliditylang.org/2021/09/27/user-defined-value-types/
 * @custom:source https://inst.eecs.berkeley.edu/~cs61c/sp06/handout/fixedpt.html
 */
library FixedNumber {
    // --- Constants --- //

    int256 internal constant LOG2_E = 1_442695040888963407;
    int256 internal constant NATURAL_E = 2_718281828459045235;

    uint256 internal constant PI = 3_141592653589793238;
    uint256 internal constant SCALAR = 1e18; // 1.0
    uint256 internal constant HALF_SCALAR = 5e17; // 0.5

    function assembly_unwrap(Fixed256x18 x) internal pure returns (int256 y) {
        assembly {
            y := x
        }
    }

    // --- Arithmetic Operators --- //

    function eq(Fixed256x18 x, int256 y) internal pure returns (bool) {
        return Fixed256x18.unwrap(x) == y;
    }

    function gt(Fixed256x18 x, int256 y) internal pure returns (bool) {
        return Fixed256x18.unwrap(x) > y;
    }

    function gte(Fixed256x18 x, int256 y) internal pure returns (bool) {
        return Fixed256x18.unwrap(x) >= y;
    }

    function lt(Fixed256x18 x, int256 y) internal pure returns (bool val) {
        return Fixed256x18.unwrap(x) < y;
    }

    function lte(Fixed256x18 x, int256 y) internal pure returns (bool val) {
        return Fixed256x18.unwrap(x) <= y;
    }

    function add(int256 x, int256 y) internal pure returns (Fixed256x18 z) {
        assembly {
            z := add(x, y)
        }
    }

    function add(Fixed256x18 x, int256 y)
        internal
        pure
        returns (Fixed256x18 z)
    {
        assembly {
            z := add(x, y)
        }
    }

    function add(Fixed256x18 x, Fixed256x18 y)
        internal
        pure
        returns (Fixed256x18 z)
    {
        assembly {
            z := add(x, y)
        }
    }

    function add(int256 x, Fixed256x18 y)
        internal
        pure
        returns (Fixed256x18 z)
    {
        assembly {
            z := add(x, y)
        }
    }

    function sub(int256 x, int256 y) internal pure returns (int256 output) {
        assembly {
            output := sub(x, y)
        }
    }

    function sub(Fixed256x18 x, int256 y)
        internal
        pure
        returns (Fixed256x18 output)
    {
        assembly {
            output := sub(x, y)
        }
    }

    function sub(Fixed256x18 x, Fixed256x18 y)
        internal
        pure
        returns (Fixed256x18 output)
    {
        assembly {
            output := sub(x, y)
        }
    }
}
