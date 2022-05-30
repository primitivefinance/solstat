// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

function muli(
    int256 x,
    int256 y,
    int256 denominator
) pure returns (int256 z) {
    assembly {
        // Store x * y in z for now.
        z := mul(x, y)

        // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
        if iszero(
            and(iszero(iszero(denominator)), or(iszero(x), eq(sdiv(z, x), y)))
        ) {
            revert(0, 0)
        }

        // Divide z by the denominator.
        z := sdiv(z, denominator)
    }
}

function muliWad(int256 x, int256 y) pure returns (int256 z) {
    z = muli(x, y, 1e18);
}

function diviWad(int256 x, int256 y) pure returns (int256 z) {
    z = muli(x, 1e18, y);
}

error Min();

function abs(int256 input) pure returns (uint256 output) {
    if (input == type(int256).min) revert Min();
    if (input < 0) {
        assembly {
            output := add(not(input), 1)
        }
    } else {
        assembly {
            output := input
        }
    }
}

/**
 * @title Gaussian Math Library.
 * @author @alexangelj
 * @dev Models the normal distribution.
 * @custom:source Inspired by https://github.com/errcw/gaussian.
 */
library Gaussian {
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
     * @dev
     * @custom:epsilon Fractional error less than 1.2e-7.
     * @custom:source Numerical Recipes in C 2e p221
     */
    function erfc(int256 input) internal view returns (int256 output) {
        uint256 z = abs(input);
        int256 t;
        int256 step;
        int256 k;
        assembly {
            // 1 / (1 + z / 2)
            let quo := sdiv(mul(z, ONE), TWO)
            let den := add(ONE, quo)
            t := sdiv(SCALAR_SQRD, den)

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

        int256 ln = FixedPointMathLib.lnWad(diviWad(xx, TWO));
        uint256 t = uint256(muliWad(NEGATIVE_TWO, ln)).sqrt();
        assembly {
            t := mul(t, HALF_SCALAR)
        }

        int256 r;
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
            int256 err = erfc(r);
            assembly {
                err := sub(err, xx)
            }

            int256 input;
            assembly {
                input := add(not(sdiv(mul(r, r), ONE)), 1) // -(muliWad(r, r))
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
