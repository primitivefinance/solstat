// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

type UFixed18 is uint256; // 60 digits . 18 digits
type Fixed18 is int256; // 1 digit sign 59 digits . 18 digits
type BigInt is uint256; // js primitive "bigint"

library Types {
    function assembly_unwrap(Fixed18 x) internal pure returns (int256 y) {
        assembly {
            y := x
        }
    }

    function gt(Fixed18 x, int256 y) internal pure returns (bool) {
        return Fixed18.unwrap(x) > y;
    }

    function gte(Fixed18 x, int256 y) internal pure returns (bool) {
        return Fixed18.unwrap(x) >= y;
    }

    function lt(Fixed18 x, int256 y) internal pure returns (bool val) {
        return Fixed18.unwrap(x) < y;
    }

    function lte(Fixed18 x, int256 y) internal pure returns (bool val) {
        return Fixed18.unwrap(x) <= y;
    }

    function add(int256 x, int256 y) internal pure returns (Fixed18 z) {
        assembly {
            z := add(x, y)
        }
    }

    function add(Fixed18 x, int256 y) internal pure returns (Fixed18 z) {
        assembly {
            z := add(x, y)
        }
    }

    function add(Fixed18 x, Fixed18 y) internal pure returns (Fixed18 z) {
        assembly {
            z := add(x, y)
        }
    }

    function add(int256 x, Fixed18 y) internal pure returns (Fixed18 z) {
        assembly {
            z := add(x, y)
        }
    }

    function addRaw(int256 x, int256 y) internal pure returns (Fixed18 output) {
        /* unchecked {
            output = Fixed18.wrap(x + y);
        } */
        assembly {
            output := add(x, y)
        }
    }

    function addUnchecked(Fixed18 x, int256 y)
        internal
        pure
        returns (Fixed18 output)
    {
        assembly {
            output := add(x, y)
        }
        /* unchecked {
            output = Fixed18.wrap(Fixed18.unwrap(x) + y);
        } */
    }

    function sub(int256 x, int256 y) internal pure returns (int256 output) {
        assembly {
            output := sub(x, y)
        }
    }

    function sub(Fixed18 x, int256 y) internal pure returns (Fixed18 output) {
        unchecked {
            output = Fixed18.wrap(Fixed18.unwrap(x) - y);
        }
    }

    function sub(Fixed18 x, Fixed18 y) internal pure returns (Fixed18 output) {
        unchecked {
            output = Fixed18.wrap(Fixed18.unwrap(x) - Fixed18.unwrap(y));
        }
    }
}
