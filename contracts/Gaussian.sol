// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./GaussianConstants.sol";
import "./FixedMath.sol";
import "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

/**
 * @title Gaussian Math Library
 * @author alexangelj
 * @dev Models the normal distribution.
 * @custom:coauthor
 * @custom:source Inspired by https://github.com/errcw/gaussian
 */
library Gaussian {
    using FixedMath for int256;
    using FixedMath for Fixed256x18;
    using FixedPointMathLib for uint256;

    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant SQRT2 = 1_414213562373095048;
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
     * @dev
     * @custom:epsilon Fractional error less than 1.2e-7.
     * @custom:source Numerical Recipes in C 2e p221
     */
    function erfc(int256 input) internal view returns (int256 output) {
        uint256 z = input.abs();
        int256 t;
        int256 step;
        int256 k;
        assembly {
            // 1 / (1 + z / 2)
            let quo := sdiv(mul(z, ONE), TWO)
            let den := add(ONE, quo)
            t := sdiv(SCALAR_SQRD, den) // 1e18 * 1e18 / denominator

            function muli(x, y) -> res {
                res := sdiv(mul(x, y), ONE)
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

        //k = (SIGN * muliWad(int256(z), int256(z)) - ERFC_A) + step0;

        /* {
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
        } */
        {
            int256 _t = t;
            /* int256 yeet = muliWad(
                _t,
                (ERFC_B +
                    muliWad(
                        _t,
                        (ERFC_C +
                            muliWad(
                                _t,
                                (ERFC_D +
                                    muliWad(_t, (ERFC_E + muliWad(_t, step0))))
                            ))
                    ))
            );
            k = int256(SIGN) * muliWad(int256(z), int256(z)) - ERFC_A + yeet; */
            /* k =
                int256(SIGN) *
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
                ); */
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

        //int256 r = muliWad(t, exp);
        //output = (input < 0) ? TWO - r : r;
    }

    /**
     * @notice Approximation of the Imaginary Complimentary Error Function.
     * @dev Domain is (0, 2)
     * @custom:source Numerical Recipes 3e p265.
     */
    function ierfc(int256 x) internal view returns (int256 z) {
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
        }

        uint256 i;
        while (i < 2) {
            int256 err = erfc(r) - xx;
            int256 exp = FixedPointMathLib.expWad(-(muliWad(r, r)));
            int256 denom = muliWad(IERFC_F, exp) - muliWad(r, err);
            r += diviWad(err, denom);
            unchecked {
                ++i;
            }
        }

        z = x < ONE ? r : -r;
    }

    /**
     * @notice Approximation of the Cumulative Distribution Function.
     * @dev
     * @custom:source
     */
    function cdf(int256 x) internal view returns (int256 z) {
        int256 negated;
        assembly {
            let res := sdiv(mul(x, ONE), SQRT2)
            negated := add(not(res), 1)
        }

        int256 erfc = erfc(negated);
        assembly {
            z := sdiv(mul(ONE, erfc), TWO)
        }
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
        assembly {
            x := mul(x, 2)
        }

        int256 _ierfc = ierfc(x);

        assembly {
            let res := sdiv(mul(SQRT2, _ierfc), ONE)
            z := add(1, not(res))
        }
    }
}
