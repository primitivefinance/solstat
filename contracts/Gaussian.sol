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
    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant NEGATIVE_TWO = -2e18;
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

            function muli(pxn, pxd) -> res {
                res := sdiv(mul(pxn, pxd), ONE)
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

        int256 xx; // = (x < ONE) ? x : TWO - x;
        assembly {
            switch iszero(slt(x, ONE))
            case 0 {
                xx := x
            }
            case 1 {
                xx := sub(TWO, x)
            }
        }

        int256 ln = FixedPointMathLib.lnWad(diviWad(xx, TWO)); // ln( xx / 2)
        int256 t = muliWad(NEGATIVE_TWO, ln).sqrt(); //int256(FixedPointMathLib.sqrt(uint256(muliWad(-TWO, ln))));
        assembly {
            t := mul(t, HALF_SCALAR)
        }
        int256 r;

        /* {
            int256 step1 = (IERFC_B + muliWad(t, IERFC_C));
            int256 step2 = (ONE + muliWad(t, (IERFC_D + muliWad(t, IERFC_E))));
            r = muliWad(IERFC_A, diviWad(step1, step2) - t);
        } */

        assembly {
            function muli(pxn, pxd) -> res {
                res := sdiv(mul(pxn, pxd), ONE)
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
            int256 err = erfc(r); //  = erfc(r) - xx;
            assembly {
                err := sub(err, xx)
            }

            int256 input; // -(muliWad(r, r))
            assembly {
                input := add(not(sdiv(mul(r, r), ONE)), 1)
            }

            int256 expWad = input.expWad(); //  = FixedPointMathLib.expWad(-(muliWad(r, r)));

            //int256 denom = muliWad(IERFC_F, expWad) - muliWad(r, err);
            //r += diviWad(err, denom);
            //unchecked {
            //    ++itr;
            //}

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

        // z = x < ONE ? r : -r;
        assembly {
            switch iszero(slt(x, ONE))
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
