// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./GaussianConstants.sol";
import "./FixedMath.sol";
import "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

import "hardhat/console.sol";

/**
 * @title Gaussian Math Library
 * @author alexangelj
 * @dev Models the normal distribution.
 * @custom:coauthor
 * @custom:source Inspired by https://github.com/errcw/gaussian.
 */
library Gaussian {
    using FixedMath for Fixed256x18;
    using FixedPointMathLib for uint256;

    struct Model {
        uint256 mean;
        uint256 variance;
    }

    int256 internal constant SCALAR = 1e18;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant ERFC_A = 1_265512230000000000;
    int256 internal constant ERFC_B = 1_000023680000000000;
    int256 internal constant ERFC_C = 374091960000000000; // 1e-1
    int256 internal constant ERFC_D = 96784180000000000; // 1e-2
    int256 internal constant ERFC_E = -186288060000000000; // 1e-1
    int256 internal constant ERFC_F = 278868070000000000; // 1e-1
    int256 internal constant ERFC_G = -1_135203980000000000;
    int256 internal constant ERFC_H = 1_488515870000000000;
    int256 internal constant ERFC_I = -822152230000000000; // 1e-1
    int256 internal constant ERFC_J = 170872770000000000; // 1e-1

    function muli(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(sdiv(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := sdiv(z, denominator)
        }
    }

    function muliWad(int256 x, int256 y) internal pure returns (int256 z) {
        z = muli(x, y, ONE);
    }

    /**
     * @notice Approximation of the Complimentary Error Function.
     * @dev
     * @custom:epsilon Fractional error less than 1.2e-7.
     * @custom:source Numerical Recipes in C 2e p221
     */
    function erfc(int256 input) internal view returns (int256 output) {
        uint256 z = UFixed256x18.unwrap(Fixed256x18.wrap(input).abs());
        int256 t = int256(
            uint256(ONE).divWadDown(
                uint256(uint256(ONE) + uint256(z).divWadDown(uint256(TWO)))
            )
        );
        console.logInt(t);
        int256 k;
        int256 step0;
        {
            int256 _t = t;
            unchecked {
                step0 = (ERFC_F +
                    muliWad(
                        _t,
                        (ERFC_G +
                            muliWad(
                                _t,
                                (ERFC_H +
                                    muliWad(_t, (ERFC_I + muliWad(_t, ERFC_J))))
                            ))
                    ));
            }
        }
        {
            int256 _t = t;
            unchecked {
                k =
                    int256(-1) *
                    muliWad(int256(z), int256(z)) -
                    ERFC_A +
                    muliWad(
                        _t,
                        (ERFC_B +
                            muliWad(
                                _t,
                                (ERFC_C +
                                    muliWad(
                                        _t,
                                        (ERFC_D +
                                            muliWad(
                                                _t,
                                                (ERFC_E + muliWad(_t, step0))
                                            ))
                                    ))
                            ))
                    );
            }
        }
        /* unchecked {
                k = (ERFC_A +
                    muliWad(
                        _t,
                        (ERFC_B +
                            muliWad(
                                _t,
                                (ERFC_C +
                                    muliWad(
                                        _t,
                                        (ERFC_D +
                                            muliWad(
                                                _t,
                                                (ERFC_E +
                                                    muliWad(
                                                        _t,
                                                        (ERFC_F +
                                                            muliWad(
                                                                _t,
                                                                (ERFC_G +
                                                                    muliWad(
                                                                        _t,
                                                                        (ERFC_H +
                                                                            muliWad(
                                                                                _t,
                                                                                (ERFC_I +
                                                                                    muliWad(
                                                                                        _t,
                                                                                        ERFC_J
                                                                                    ))
                                                                            ))
                                                                    ))
                                                            ))
                                                    ))
                                            ))
                                    ))
                            ))
                    ));
            } */

        console.logInt(k);

        int256 znot;
        assembly {
            znot := add(not(z), 1)
        }

        int256 exp = FixedPointMathLib.expWad(k);

        console.logInt(exp);

        int256 r = muliWad(t, exp);

        console.logInt(r);

        output = (input < ONE) ? TWO - r : r;

        console.logInt(output);
    }

    /**
     * @notice Approximation of the Imaginary Complimentary Error Function.
     * @dev
     * @custom:source Numerical Recipes 3e p265.
     */
    function ierfc() internal pure returns (uint256) {}

    /**
     * @notice Approximation of the Cumulative Distribution Function.
     * @dev
     * @custom:source
     */
    function cdf() internal pure returns (uint256) {}

    /**
     * @notice Approximation of the Probability Density Function.
     * @dev
     * @custom:source
     */
    function pdf() internal pure returns (uint256) {}

    /**
     * @notice Approximation of the Percent Point Function.
     * @dev
     * @custom:source
     */
    function ppf() internal pure returns (uint256) {}
}
