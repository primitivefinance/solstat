// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solmate/utils/FixedPointMathLib.sol";
import "../Units.sol";

/**
 * @title Gaussian Math Library.
 * @author @alexangelj
 *
 * @notice Models the normal distribution using the special Complimentary Error Function.
 *
 * @dev Only implements a distribution with mean (µ) = 0 and variance (σ) = 1.
 * Uses Numerical Recipes as a framework and reference C implemenation.
 * Numerical Recipes cites the original textbook written by Abramowitz and Stegun,
 * "Handbook of Mathematical Functions", which should be read to understand these
 * special functions and the implications of their numerical approximations.
 *
 * @custom:source Handbook of Mathematical Functions https://personal.math.ubc.ca/~cbm/aands/abramowitz_and_stegun.pdf.
 * @custom:source Numerical Recipes https://e-maxx.ru/bookz/files/numerical_recipes.pdf.
 * @custom:source Inspired by https://github.com/errcw/gaussian.
 */
library Gaussian {
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    error Infinity();
    error NegativeInfinity();
    error Overflow();
    error OutOfBounds();

    uint256 internal constant HALF_WAD = 0.5 ether;
    uint256 internal constant PI = 3_141592653589793238;
    int256 internal constant SQRT_2PI = 2_506628274631000502;
    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant NEGATIVE_TWO = -2e18;
    int256 internal constant SQRT2 = 1_414213562373095048; // √2 with 18 decimals of precision.
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

    /**
     * @notice Approximation of the Complimentary Error Function.
     * Related to the Error Function: `erfc(x) = 1 - erf(x)`.
     * Both cumulative distribution and error functions are integrals
     * which cannot be expressed in elementary terms. They are called special functions.
     * The error and complimentary error functions have numerical approximations
     * which is what is used in this library to compute the cumulative distribution function.
     *
     * @dev This is a special function with its own identities.
     * Identity: `erfc(-x) = 2 - erfc(x)`.
     * Special Values:
     * erfc(-infinity)	=	2
     * erfc(0)      	=	1
     * erfc(infinity)	=	0
     *
     * @custom:epsilon Fractional error less than 1.2e-7.
     * @custom:source Numerical Recipes in C 2e p221.
     * @custom:source https://mathworld.wolfram.com/Erfc.html.
     */
    function erfc(int256 input) internal pure returns (int256 output) {
        if (input == 0) {
            return 1 ether;
        }

        uint256 z = abs(input);
        int256 t;
        int256 step;
        int256 k;

        assembly {
            let quo := sdiv(mul(z, ONE), TWO) // 1 / (1 + z / 2).
            let den := add(ONE, quo)
            t := sdiv(SCALAR_SQRD, den)

            function muli(pxn, pxd) -> res {
                res := mul(pxn, pxd)

                if iszero(eq(sdiv(res, pxn), pxd)) {
                    mstore(0, 0x35278d1200000000000000000000000000000000000000000000000000000000)
                    revert(0, 4)
                }

                res := sdiv(res, ONE)
            }

            {
                step := add(
                    ERFC_F,
                    muli(
                        t,
                        add(
                            ERFC_G,
                            muli(
                                t,
                                add(
                                    ERFC_H,
                                    muli(t, add(ERFC_I, muli(t, ERFC_J)))
                                )
                            )
                        )
                    )
                )
            }
            {
                step := muli(
                    t,
                    add(
                        ERFC_B,
                        muli(
                            t,
                            add(
                                ERFC_C,
                                muli(
                                    t,
                                    add(
                                        ERFC_D,
                                        muli(t, add(ERFC_E, muli(t, step)))
                                    )
                                )
                            )
                        )
                    )
                )
            }

            k := add(sub(mul(SIGN, muli(z, z)), ERFC_A), step)
        }

        int256 expWad = FixedPointMathLib.expWad(k);
        int256 r;
        assembly {
            r := sdiv(mul(t, expWad), ONE)
            switch iszero(slt(input, 0))
            case 0 {
                output := sub(TWO, r)
            }
            case 1 {
                output := r
            }
        }
    }

    /**
     * @notice Approximation of the Inverse Complimentary Error Function - erfc^(-1).
     *
     * @dev Equal to `ierfc(erfc(x)) = erfc(ierfc(x))` for 0 < x < 2.
     * Related to the Inverse Error Function: `ierfc(1 - x) = ierf(x)`.
     * This is a special function with its own identities.
     * Domain:      0 < x < 2
     * Special values:
     * ierfc(0)	=	infinity
     * ierfc(1)	=	0
     * ierfc(2)	=	-infinity
     *
     * @custom:source Numerical Recipes 3e p265.
     * @custom:source https://mathworld.wolfram.com/InverseErfc.html.
     */
    function ierfc(int256 x) internal pure returns (int256 z) {
        if (x == 0 || x == 2 ether) revert Infinity();
        if (x < 0 || x > 2 ether) revert OutOfBounds();

        assembly {
            // x >= 2, iszero(x < 2 ? 1 : 0) ? 1 : 0.
            if iszero(slt(x, TWO)) {
                z := mul(add(not(100), 1), SCALAR)
            }

            // x <= 0.
            if iszero(sgt(x, 0)) {
                z := mul(100, SCALAR)
            }
        }

        if (z != 0) return z;

        int256 xx; // (x < ONE) ? x : TWO - x.
        assembly {
            switch iszero(slt(x, ONE))
            case 0 {
                xx := x
            }
            case 1 {
                xx := sub(TWO, x)
            }
        }

        int256 logInput = diviWad(xx, TWO);
        if (logInput == 0) revert Infinity();
        int256 ln = FixedPointMathLib.lnWad(logInput);
        uint256 t = uint256(muliWad(NEGATIVE_TWO, ln)).sqrt();
        assembly {
            t := mul(t, HALF_SCALAR)
        }

        int256 r;
        assembly {
            function muli(pxn, pxd) -> res {
                res := mul(pxn, pxd)

                if iszero(eq(sdiv(res, pxn), pxd)) {
                    mstore(0, 0x35278d1200000000000000000000000000000000000000000000000000000000)
                    revert(0, 4)
                }

                res := sdiv(res, ONE)
            }

            r := muli(
                IERFC_A,
                sub(
                    sdiv(
                        mul(add(IERFC_B, muli(t, IERFC_C)), ONE),
                        add(ONE, muli(t, add(IERFC_D, muli(t, IERFC_E))))
                    ),
                    t
                )
            )
        }

        uint256 itr;
        while (itr < 2) {
            int256 err = erfc(r);
            assembly {
                err := sub(err, xx)
            }

            int256 input;
            assembly {
                input := add(not(sdiv(mul(r, r), ONE)), 1) // -(r * r).
            }

            int256 expWad = input.expWad();

            assembly {
                function muli(pxn, pxd) -> res {
                    res := sdiv(mul(pxn, pxd), ONE)
                }

                r := add(
                    r,
                    sdiv(
                        mul(err, ONE),
                        sub(muli(IERFC_F, expWad), muli(r, err))
                    )
                )

                itr := add(itr, 1)
            }
        }

        assembly {
            switch iszero(slt(x, ONE)) // x < ONE ? r : -r.
            case 0 {
                z := r
            }
            case 1 {
                z := add(not(r), 1)
            }
        }
    }

    /**
     * @notice Approximation of the Cumulative Distribution Function.
     *
     * @dev Equal to `D(x) = 0.5[ 1 + erf((x - µ) / σ√2)]`.
     * Only computes cdf of a distribution with µ = 0 and σ = 1.
     *
     * @custom:error Maximum error of 1.2e-7.
     * @custom:source https://mathworld.wolfram.com/NormalDistribution.html.
     */
    function cdf(int256 x) internal pure returns (int256 z) {
        int256 negated;

        assembly {
            let res := sdiv(mul(x, ONE), SQRT2)
            negated := add(not(res), 1)
        }

        int256 _erfc = erfc(negated);

        assembly {
            z := sdiv(mul(ONE, _erfc), TWO)
        }
    }

    /**
     * @notice Approximation of the Probability Density Function.
     *
     * @dev Equal to `Z(x) = (1 / σ√2π)e^( (-(x - µ)^2) / 2σ^2 )`.
     * Only computes pdf of a distribution with µ = 0 and σ = 1.
     *
     * @custom:error Maximum error of 1.2e-7.
     * @custom:source https://mathworld.wolfram.com/ProbabilityDensityFunction.html.
     */
    function pdf(int256 x) internal pure returns (int256 z) {
        int256 e;

        assembly {
            e := sdiv(mul(add(not(x), 1), x), TWO) // (-x * x) / 2.
        }

        e = FixedPointMathLib.expWad(e);

        assembly {
            z := sdiv(mul(e, ONE), SQRT_2PI)
        }
    }

    /**
     * @notice Approximation of the Percent Point Function.
     *
     * @dev Equal to `D(x)^(-1) = µ - σ√2(ierfc(2x))`.
     * Only computes ppf of a distribution with µ = 0 and σ = 1.
     *
     * @custom:error Maximum error of 1.2e-7 compared to "real" ierfc.
     * @custom:error Maximum error of 1e-14 in differential tests vs. javscript implementation.
     * This error is for inputs near the upper bound >= 0.99 wad.
     * JS uses 64bit floats naturally. 12 bits are assigned to the sign and exponent. 
     * This leaves 52bit to represent the decimal. 
     * Taking log_10(2^52) gives roughly 15.65. 
     * This means that we can really only get 15 digits of accuracy from JS itself.
     * The error is in this conversion from fixed point to floating point.
     * @custom:source https://mathworld.wolfram.com/NormalDistribution.html.
     */
    function ppf(int256 x) internal pure returns (int256 z) {
        if (x == int256(HALF_WAD)) return int256(0); // returns 3.75e-8, but we know it's zero.
        if (x >= ONE) revert Infinity();
        if (x == 0) revert NegativeInfinity();
        assembly {
            x := mul(x, 2)
        }

        int256 _ierfc = ierfc(x);

        assembly {
            let res := sdiv(mul(SQRT2, _ierfc), ONE)
            z := add(not(res), 1) // -res.
        }
    }
}
