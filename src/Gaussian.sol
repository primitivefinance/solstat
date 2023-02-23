// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solmate/utils/FixedPointMathLib.sol";
import "./Units.sol";

/**
 * @title Gaussian Math Library.
 * @author @alexangelj
 * @custom:coauthor @0xjepsen
 * @custom:coauthor @autoparallel
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
    using {abs, diviWad} for int256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    error Infinity();
    error NegativeInfinity();
    error OutOfBounds();

    uint256 internal constant WAD = 1 ether;
    uint256 internal constant HALF_WAD = 0.5 ether;
    uint256 internal constant DOUBLE_WAD = 2 ether;
    uint256 internal constant PI = 3_141592653589793238;
    int256 internal constant ERFC_DOMAIN_UPPER = int256(6.24 ether);
    int256 internal constant ERFC_DOMAIN_LOWER = -ERFC_DOMAIN_UPPER;
    int256 internal constant SQRT_2PI = 2_506628274631000502;
    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1 ether;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1 ether;
    int256 internal constant TWO = 2 ether;
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
     * As `input` approaches ∞ or -∞, `output` returns 0 or 2 wad respectively.
     * Once `input` is ~6.24 wad, it returns these values because of only having 15 decimals of precision.
     * Identity: `erfc(-x) = 2 - erfc(x)`.
     * Special Values:
     * erfc(-∞)	=	2
     * erfc(0)  =	1
     * erfc(∞)	=	0
     *
     * @custom:epsilon Fractional error less than 1.2e-7.
     * @custom:error Maximum error of 1e-15 compared to Gaussian.js library.
     * @custom:source Numerical Recipes in C 2e p221.
     * @custom:source https://mathworld.wolfram.com/Erfc.html.
     */
    function erfc(int256 input) internal pure returns (int256 output) {
        if (input == 0) return ONE;
        if (input >= ERFC_DOMAIN_UPPER) return 0;
        if (input <= ERFC_DOMAIN_LOWER) return TWO;

        uint256 z = input.abs(); // |z|
        int256 t = diviWad(ONE, (ONE + int256(z.divWadDown(DOUBLE_WAD)))); // 1 / (1 + z / 2)

        int256 k;
        int256 step;

        {
            // Avoids stack too deep.
            int256 _t = t;

            step =
                (ERFC_F + muliWad(_t, (ERFC_G + muliWad(_t, (ERFC_H + muliWad(_t, (ERFC_I + muliWad(_t, ERFC_J))))))));
        }

        {
            int256 _t = t;
            step = muliWad(
                _t, (ERFC_B + muliWad(_t, (ERFC_C + muliWad(_t, (ERFC_D + muliWad(_t, (ERFC_E + muliWad(_t, step))))))))
            );

            k = (int256(-1) * muliWad(int256(z), int256(z)) - ERFC_A) + step;
        }

        int256 exp = k.expWad();
        int256 r = muliWad(t, exp);
        output = (input < 0) ? TWO - r : r;
    }

    /**
     * @notice Approximation of the Inverse Complimentary Error Function - erfc^(-1).
     *
     * @dev Equal to `ierfc(erfc(x)) = erfc(ierfc(x))` for 0 < x < 2.
     * Related to the Inverse Error Function: `ierfc(1 - x) = ierf(x)`.
     * This is a special function with its own identities.
     * Domain: 0 < x < 2
     * Special values:
     * ierfc(0)	=	∞
     * ierfc(1)	=	0
     * ierfc(2)	=  -∞
     *
     * @custom:error Maximum error of 1e-15 compared to Gaussian.js library.
     * @custom:source Numerical Recipes 3e p265.
     * @custom:source https://mathworld.wolfram.com/InverseErfc.html.
     */
    function ierfc(int256 x) internal pure returns (int256 z) {
        if (x < 0 || x > 2 ether) revert OutOfBounds();
        if (x == 0) revert Infinity();
        if (x == 2 ether) revert NegativeInfinity();
        if (z != 0) return z;

        int256 xx = (x < ONE) ? x : TWO - x;
        int256 logInput = xx.diviWad(TWO);
        if (logInput == 0) revert Infinity();
        int256 ln = logInput.lnWad(); // ln( xx / 2)
        int256 t = int256(uint256(muliWad(-TWO, ln)).sqrt()) * HALF_SCALAR;

        int256 r;
        {
            int256 numerator = (IERFC_B + muliWad(t, IERFC_C));
            int256 denominator = (ONE + muliWad(t, (IERFC_D + muliWad(t, IERFC_E))));
            r = muliWad(IERFC_A, diviWad(numerator, denominator) - t);
        }

        uint256 i;
        while (i < 2) {
            int256 err = erfc(r) - xx;
            int256 input = -(muliWad(r, r)); // -(r * r)
            int256 expWad = input.expWad();
            int256 denom = muliWad(IERFC_F, expWad) - muliWad(r, err);
            r = r + diviWad(err, denom);
            unchecked {
                ++i;
            }
        }

        z = x < ONE ? r : -r;
    }

    /**
     * @notice Approximation of the Cumulative Distribution Function.
     *
     * @dev Equal to `D(x) = 0.5[ 1 + erf((x - µ) / σ√2)]`.
     * Only computes cdf of a distribution with µ = 0 and σ = 1.
     *
     * @custom:rounding Rounds down via truncation from division.
     * @custom:error Maximum error of 1.2e-7 compared to theoretical cdf.
     * @custom:error Maximum error of 1e-15 compared to Gaussian.js library.
     * @custom:source https://mathworld.wolfram.com/NormalDistribution.html.
     */
    function cdf(int256 x) internal pure returns (int256 z) {
        int256 input = (x * ONE) / SQRT2;
        int256 negated = -input;
        int256 _erfc = erfc(negated);
        z = (_erfc * ONE) / TWO;
    }

    /**
     * @notice Approximation of the Probability Density Function.
     *
     * @dev Equal to `Z(x) = (1 / σ√2π)e^( (-(x - µ)^2) / 2σ^2 )`.
     * Only computes pdf of a distribution with µ = 0 and σ = 1.
     *
     * @custom:rounding Rounds down via truncation from division.
     * @custom:error Maximum error of 1.2e-7 compared to theoretical pdf.
     * @custom:error Maximum error of 1e-15 compared to Gaussian.js library.
     * @custom:source https://mathworld.wolfram.com/ProbabilityDensityFunction.html.
     */
    function pdf(int256 x) internal pure returns (int256 z) {
        int256 e = (-x * x) / TWO;
        e = e.expWad();
        z = (e * ONE) / SQRT_2PI;
    }

    /**
     * @notice Approximation of the Percent Point Function.
     *
     * @dev Equal to `D(x)^(-1) = µ - σ√2(ierfc(2x))`.
     * Only computes ppf of a distribution with µ = 0 and σ = 1.
     *
     * @custom:error Maximum error of 1.2e-7 compared to theoretical ierfc.
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
        if (x == int256(HALF_WAD)) return int256(0);
        if (x >= ONE) revert Infinity();
        if (x == 0) revert NegativeInfinity();
        int256 double = x * 2;
        int256 _ierfc = ierfc(double);
        int256 res = muliWad(SQRT2, _ierfc);
        z = -res;
    }
}
