// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Types.sol";

/**
 * @title Solidity Math.
 * @author alexangelj
 * @dev Basic arithmetic for the types supported by these libraries.
 */
library SMath {
    using Types for Fixed18;

    uint256 public constant UZERO = 0;
    int256 public constant ZERO = 0;
    uint256 public constant POSITIVE = 0;
    uint256 public constant NEGATIVE = 1;
    int256 public constant MIN_INT = type(int256).min;

    error Min();

    function rawAbs(int256 input) internal pure returns (uint256 output) {
        if (input == MIN_INT) revert Min();

        if (input < ZERO) {
            assembly {
                output := add(not(input), 1)
            }
        } else {
            assembly {
                output := input
            }
        }
    }

    function abs(Fixed18 input) internal pure returns (UFixed18 output) {
        if (Fixed18.unwrap(input) == MIN_INT) revert Min();

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

    function absUnchecked(Fixed18 input)
        internal
        pure
        returns (UFixed18 output)
    {
        if (Fixed18.unwrap(input) == type(int128).min) revert Min();

        unchecked {
            output = UFixed18.wrap(
                uint256(
                    Fixed18.unwrap(
                        input.gte(0)
                            ? input
                            : Fixed18.wrap(-Fixed18.unwrap(input))
                    )
                )
            );
        }
    }
}
