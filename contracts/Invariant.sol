// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./FixedMath.sol";
import "./Gaussian.sol";
import "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

/**
 * @title Invariant of Primitive RMM.
 * @notice Invariant is `k = y - KΦ(Φ⁻¹(1-x) - σ√τ)`.
 *
 * @dev Terms which can potentially be ambiguous are given discrete names.
 * This makes it easier to search for terms and update terms.
 * Variables can sometimes not be trusted to be or act like their names.
 * This naming scheme avoids this problem using a glossary to define them.
 *
 * // ------------------ Glossary ------------------ //
 *
 * `R_x` - Amount of base token reserves per single unit of liquidity. Units are unsigned SCALAR.
 * `R_y` - Amount of quote token reserves per single unit of liquidity. Units are unsigned SCALAR.
 * `stk` - Strike price of the pool. The terminal price of each base token. Units are unsigned SCALAR.
 * `vol` - Implied volatility of the pool. Higher vol = lower $ value per liquidity. Units are unsigned SCALAR.
 * `tau` - Time until maturity of pool. Amount of seconds until the pool's curve becomes flat around `stk`. Units are YEAR.
 * `inv` - Invariant of the pool. Difference between theoretical $ value and actual $ value per liquidity. Units are signed SCALAR.
 *
 * // ------------------ Units ------------------ //
 *
 * `SCALAR` - Equal to `1.` with 18 decimals. Either signed or unsigned.
 * `YEAR`   - Equal to the amount of seconds in a year. Used in `invariant` function.
 *
 * // ------------------ Error Bounds ------------------ //
 *
 * `invariant` - 1e-9
 * `
 *
 */
library Invariant {
    using Gaussian for int256;
    using FixedMath for int256;
    using FixedPointMathLib for uint256;

    int256 internal constant ONE = 1e18;
    int256 internal constant YEAR = 31556952;
    int256 internal constant HALF_SCALAR = 1e9;

    error Bad();

    function getY(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal view returns (uint256 R_y) {
        if (tau < 0) revert Bad();
        if (tau != 0) {
            int256 sec;
            assembly {
                // Scales amount of seconds to units of `SCALAR`. The `tau` must be in units of `YEAR`.
                // For example, if `tau` == `YEAR`, `sec` will be `SCALAR`, which is equal to one year.
                sec := sdiv(mul(tau, ONE), YEAR)
            }

            int256 sdr = sec.sqrt();
            assembly {
                sdr := mul(sdr, HALF_SCALAR)
                sdr := sdiv(mul(vol, sdr), ONE)
            }

            int256 phi;
            assembly {
                phi := sub(ONE, R_x)
            }
            phi = phi.ppf();

            int256 cdf;
            assembly {
                cdf := sub(phi, sdr)
            }
            cdf = cdf.cdf();

            assembly {
                R_y := sdiv(mul(stk, cdf), ONE)
            }
        } else {
            assembly {
                // `stk` is in SCALAR, ONE - R_x is in SCALAR, so SCALAR * SCALAR / SCALAR = SCALAR.
                R_y := sdiv(mul(stk, sub(ONE, R_x)), ONE)
            }
        }
    }

    function getX(
        uint256 R_y,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal view returns (uint256 R_x) {
        int256 sec;
        assembly {
            sec := div(mul(tau, ONE), YEAR)
        }
        int256 sdr = sec.sqrt();

        int256 phi;
        assembly {
            sdr := mul(sdr, HALF_SCALAR)
            sdr := div(mul(vol, sdr), ONE)
            phi := sdiv(mul(R_y, ONE), stk)
        }
        phi = phi.ppf();

        int256 cdf;
        assembly {
            cdf := add(phi, sdr)
        }
        cdf = cdf.cdf();

        assembly {
            R_x := sub(ONE, cdf)
        }
    }

    function invariant(
        uint256 R_y,
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal view returns (int256 inv) {
        uint256 y = getY(R_x, stk, vol, tau);
        assembly {
            inv := sub(R_y, y)
        }
    }
}
