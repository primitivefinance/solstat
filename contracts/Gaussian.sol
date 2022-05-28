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

    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF = 5e17;
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

    int256 internal constant IERFC_A = -707110000000000000; // 1e-1
    int256 internal constant IERFC_B = 2_307530000000000000;
    int256 internal constant IERFC_C = 270610000000000000; // 1e-1
    int256 internal constant IERFC_D = 992290000000000000; // 1e-1
    int256 internal constant IERFC_E = 44810000000000000; // 1e-2
    int256 internal constant IERFC_F = 1_128379167095512570;

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

    function diviWad(int256 x, int256 y) internal pure returns (int256 z) {
        z = muli(x, ONE, y);
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

        int256 k;
        int256 step0;

        {
            // Avoids stack too deep.
            int256 _t = t;

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
        {
            int256 _t = t;

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

        int256 exp = FixedPointMathLib.expWad(k);
        int256 r = muliWad(t, exp);
        output = (input < 0) ? TWO - r : r;

        //console.logInt(t);
        //console.logInt(k);
        //console.logInt(exp);
        //console.logInt(r);
        //console.logInt(output);
    }

    /**
     * @notice Approximation of the Imaginary Complimentary Error Function.
     * @dev Domain is (0, 2)
     * @custom:source Numerical Recipes 3e p265.
     */
    function ierfc(int256 x) internal view returns (int256 z) {
        console.log("enter");
        assembly {
            // x >= 2, iszero(x < 2 ? 1 : 0) ? 1 : 0
            if iszero(slt(x, TWO)) {
                z := mul(add(not(100), 1), SCALAR)
            }

            // x <= 0
            if iszero(sgt(x, 0)) {
                z := mul(100, SCALAR)
            }
        }

        /* if (x >= TWO) return -100 * SCALAR;
        if (x <= 0) return 100 * SCALAR; */
        if (z != 0) return z;

        int256 xx = (x < ONE) ? x : TWO - x;
        int256 ln = FixedPointMathLib.lnWad(diviWad(xx, TWO)); // ln( xx / 2)
        int256 t = int256(FixedPointMathLib.sqrt(uint256(muliWad(-TWO, ln))));
        assembly {
            t := mul(t, HALF_SCALAR)
        }
        int256 r;

        {
            int256 step0 = IERFC_A;
            int256 step1 = (IERFC_B + muliWad(t, IERFC_C));
            int256 step2 = (ONE + muliWad(t, (IERFC_D + muliWad(t, IERFC_E))));
            r = muliWad(step0, diviWad(step1, step2) - t);
            /* r = muliWad(
                IERFC_A,
                (
                    diviWad(
                        (IERFC_B + muliWad(t, IERFC_C)),
                        (ONE + muliWad(t, (IERFC_D + muliWad(t, IERFC_E)))) - t
                    )
                )
            ); */
        }

        console.logInt(xx);
        console.logInt(t);
        console.logInt(r);
        uint256 i;
        console.log("loop");
        while (i < 2) {
            int256 err = erfc(r) - xx;
            int256 exp = FixedPointMathLib.expWad(-(muliWad(r, r)));
            int256 denom = muliWad(IERFC_F, exp) - muliWad(r, err);
            r += diviWad(err, denom);
            console.logInt(err);
            console.logInt(r);
            unchecked {
                ++i;
            }
        }

        z = x < ONE ? r : -r;
        console.logInt(r);
        console.logInt(z);
    }

    /**
     * @notice Approximation of the Cumulative Distribution Function.
     * @dev
     * @custom:source
     */
    function cdf(int256 x) internal view returns (int256 z) {
        int256 sqrt2 = int256(FixedPointMathLib.sqrt(uint256(TWO)));
        console.logInt(sqrt2);
        //int256 input = diviWad(x, sqrt2);
        int256 input;
        assembly {
            input := sdiv(mul(SCALAR, x), mul(HALF_SCALAR, sqrt2))
        }

        console.logInt(input);
        int256 negated;
        assembly {
            negated := add(not(input), 1)
        }
        console.logInt(negated);

        console.log("getting erfc");
        int256 erfc = erfc(negated);

        console.logInt(erfc);
        assembly {
            z := sdiv(mul(ONE, erfc), TWO)
        }

        console.logInt(z);
    }

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
    function ppf(int256 x) internal view returns (int256 z) {
        int256 sqrt2 = int256(FixedPointMathLib.sqrt(uint256(TWO)));
        assembly {
            sqrt2 := mul(sqrt2, HALF_SCALAR)
        }

        int256 double;
        assembly {
            double := mul(x, 2)
        }

        int256 _ierfc = ierfc(double);

        int256 res = muliWad(sqrt2, _ierfc);

        assembly {
            z := add(1, not(res))
        }
    }
}
