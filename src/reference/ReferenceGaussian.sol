// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solmate/utils/FixedPointMathLib.sol";
import "../Units.sol";

/**
 * @title Gaussian Math Library
 * @author @alexangelj
 * @dev Models the normal distribution.
 * @custom:coauthor @0xjepsen
 * @custom:source Inspired by https://github.com/errcw/gaussian
 */
library Gaussian {
    using { abs, diviWad } for int256;
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    error Infinity();
    error NegativeInfinity();

    uint256 internal constant WAD = 1 ether;
    uint256 internal constant HALF_WAD = 0.5 ether;
    uint256 internal constant DOUBLE_WAD = 2 ether;
    uint256 internal constant PI = 3_141592653589793238;
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

    function erfc(int256 input) internal pure returns (int256 output) {
        uint256 z = input.abs();
        // 1 / (1 + z / 2)
        int256 t = int256(WAD.divWadDown((WAD + z.divWadDown(DOUBLE_WAD))));

        int256 k;
        int256 step;

        {
            // Avoids stack too deep.
            int256 _t = t;

            step = (ERFC_F +
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
            step = muliWad(
                _t,
                (ERFC_B +
                    muliWad(
                        _t,
                        (ERFC_C +
                            muliWad(
                                _t,
                                (ERFC_D +
                                    muliWad(_t, (ERFC_E + muliWad(_t, step))))
                            ))
                    ))
            );

            k = (int256(-1) * muliWad(int256(z), int256(z)) - ERFC_A) + step;
        }

        int256 exp = k.expWad();
        int256 r = muliWad(t, exp);
        output = (input < 0) ? TWO - r : r;
    }

    function ierfc(int256 x) internal pure returns (int256 z) {
        if (x >= TWO) return -int256(100) * SCALAR;
        if (x <= 0) return 100 * SCALAR;
        if (z != 0) return z;

        int256 xx = (x < ONE) ? x : TWO - x;
        int256 logInput = xx.diviWad(TWO);
        if(logInput == 0) revert Infinity();
        int256 ln = logInput.lnWad(); // ln( xx / 2)
        int256 t = int256(uint256(muliWad(-TWO, ln)).sqrt()) * HALF_SCALAR;

        int256 r;
        {
            int256 numerator = (IERFC_B + muliWad(t, IERFC_C));
            int256 denominator = (ONE +
                muliWad(t, (IERFC_D + muliWad(t, IERFC_E))));
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

    function cdf(int256 x) internal pure returns (int256 z) {
        int256 input = (x * ONE) / SQRT2;
        int256 negated = -input;
        int256 _erfc = erfc(negated);
        z = (_erfc * ONE) / TWO;
    }

    function pdf(int256 x) internal pure returns (int256 z) {
        int256 e = (-x * x) / TWO;
        e = e.expWad();
        z = (e * ONE) / SQRT_2PI;
    }

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
