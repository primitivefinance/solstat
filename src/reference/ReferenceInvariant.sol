// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReferenceGaussian.sol";

/**
 * @title Invariant of Primitive RMM.
 * @author @alexangelj
 * @notice Invariant is `k` with the trading function `k = y - KΦ(Φ⁻¹(1-x) - σ√τ)`.
 *
 * @dev Terms which can potentially be ambiguous are given discrete names.
 * This makes it easier to search for terms and update terms.
 * Variables can sometimes not be trusted to be or act like their names.
 * This naming scheme avoids this problem using a glossary to define them.
 *
 * // -------------------- Glossary --------------------- //
 *
 * `R_x` - Amount of asset token reserves per single unit of liquidity.
 * `R_y` - Amount of quote token reserves per single unit of liquidity.
 * `stk` - Strike price of the pool. The terminal price of each asset token.
 * `vol` - Implied volatility of the pool. Higher vol = higher price impact on swaps.
 * `tau` - Time until the pool expires. Amount of seconds until the pool's curve becomes flat around `stk`.
 * `inv` - Invariant of the pool. Difference between theoretical $ value and actual $ value per liquidity.
 *
 * `WAD` - Signed or unsigned fixed point number with up to 18 decimals and up to 256 total bits wide.
 * `YEAR`- Equal to the amount of seconds in a year. Used in `invariant` function.
 *
 * // -------------------- Units ------------------------ //
 *
 * `R_x` - Units are unsigned WAD. Represents value of tokens, decimals matter.
 * `R_y` - Units are unsigned WAD. Represents value of tokens, decimals matter.
 * `stk` - Units are unsigned WAD. Represents value of tokens, decimals matter.
 * `vol` - Units are unsigned WAD. Represents a percentage in which 100% = WAD.
 * `tau` - Units are YEAR. Represents a time unit which `1.0` is equal to YEAR.
 * `inv` - Units are signed WAD. Initial value of zero and decreases over time.
 *
 * // -------------------- Denoted By ----------------- //
 *
 * `R_x` - Denoted by `x`.
 * `R_y` - Denoted by `y`.
 * `stk` - Denoted by `K`.
 * `vol` - Denoted by `σ`.
 * `tau` - Denoted by `τ`.
 * `inv` - Denoted by `k`.
 *
 * // -------------------- Error Bounds ----------------- //
 *
 * `inv` - Up to 1e-9.
 *
 * // ------------------------ ~ ------------------------ //
 */
library Invariant {
    using Gaussian for int256; // Uses the `cdf` and `pdf` functions.
    using FixedPointMathLib for uint256; // Uses the `sqrt` function.

    uint256 internal constant WAD = 1 ether;
    uint256 internal constant DOUBLE_WAD = 2 ether;
    int256 internal constant ONE = 1 ether;
    int256 internal constant YEAR = 31556952;
    int256 internal constant HALF_SCALAR = 1e9;

    /**
     * @dev Reverts when an input value is out of bounds of its acceptable range.
     */
    error OOB();

    /**
     * @notice Uses reserves `R_x` to compute reserves `R_y`.
     *
     * @dev Computes `y` in `y = KΦ(Φ⁻¹(1-x) - σ√τ) + k`.
     * Primary function use to compute the invariant.
     * Simplifies to `K(1 -x) + k` when time to expiry is zero.
     * Reverts if `R_x` is greater than one. Units are a fixed point number with 18 decimals.
     *
     * We handle some special cases, try this:
     * `normalcd(normalicd(1) - 0.1)` in https://keisan.casio.com/calculator
     * Gaussian.sol reverts for `ppf(1)` and `ppf(0)`, so we handle those cases.
     *
     * @param R_x Quantity of token reserve `x` within the bounds of [0, 1].
     * @param stk Strike price of the pool. Terminal price of asset `x` in the pool denominated in asset `y`.
     * @param vol Implied volatility of the pool. Higher implied volatility = higher price impact on swaps.
     * @param tau Time until the pool expires. Once expired, no swaps can happen. Scaled to units of `Invariant.YEAR`.
     * @param inv Current invariant given the actual `R_x`. Zero if computing invariant itself.
     * @return R_y Quantity of token reserve `y` within the bounds of [0, stk].
     *
     * @custom:error Technically, none. This is the source of truth for the trading function.
     * @custom:source https://primitive.xyz/whitepaper
     */
    function getY(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau,
        int256 inv
    ) internal pure returns (uint256 R_y) {
        if (R_x > WAD) revert OOB(); // Negative input for `ppf` is invalid.
        if (R_x == WAD) return uint256(inv); // For `ppf(0)` case, because 1 - 1 == 0, cdf(ppf(0)) == 0, and `y = K * 0 + k` simplifies to `y = k`.
        if (R_x == 0) return uint256(int256(stk) + inv); // For `ppf(1)` case, because 1 - 0 == 1, cdf(ppf(1)) == 1, and `y = K * 1 + k` simplifies to `y = K + k`.
        if (tau != 0) {
            // Short circuits because tau != 0 is more likely.
            uint256 sec;
            assembly {
                sec := sdiv(mul(tau, ONE), YEAR) // Unit math: YEAR * SCALAR / YEAR = SCALAR.
            }

            uint256 sdr = sec.sqrt(); // √τ.
            assembly {
                sdr := mul(sdr, HALF_SCALAR) // Unit math: sdr * HALF_SCALAR = SCALAR.
                sdr := sdiv(mul(vol, sdr), ONE) // σ√τ.
            }

            int256 phi;
            assembly {
                phi := sub(ONE, R_x)
            }
            phi = phi.ppf(); // Φ⁻¹(1-x).

            int256 cdf;
            assembly {
                cdf := sub(phi, sdr) // Φ⁻¹(1-x) - σ√τ.
            }
            cdf = cdf.cdf(); // Φ(Φ⁻¹(1-x) - σ√τ).

            assembly {
                R_y := add(sdiv(mul(stk, cdf), ONE), inv)
            }
        } else {
            assembly {
                R_y := add(sdiv(mul(stk, sub(ONE, R_x)), ONE), inv)
            }
        }
    }

    /**
     * @notice Uses reserves `R_y` to compute reserves `R_x`.
     *
     * @dev Computes `x` in `x = 1 - Φ(Φ⁻¹( (y + k) / K ) + σ√τ)`.
     * Not used in invariant function. Used for computing swap outputs.
     * Simplifies to `1 - ( (y + k) / K )` when time to expiry is zero.
     * Reverts if `R_y` is greater than one. Units are WAD.
     *
     * Dangerous! There are important bounds to using this function.
     *
     * @param R_y Quantity of token reserve `y` within the bounds of [0, stk].
     * @param stk Strike price of the pool. Terminal price of asset `x` in the pool denominated in asset `y`.
     * @param vol Implied volatility of the pool. Higher implied volatility = higher price impact on swaps.
     * @param tau Time until the pool expires. Once expired, no swaps can happen. Scaled to units of `Invariant.YEAR`.
     * @param inv Current invariant given the actual reserves `R_y`.
     * @return R_x Quantity of token reserve `x` within the bounds of [0, 1].
     *
     * @custom:error Up to 1e-6. This an **approximated** "inverse" of the `getY` function.
     * @custom:source https://primitive.xyz/whitepaper
     */
    function getX(
        uint256 R_y,
        uint256 stk,
        uint256 vol,
        uint256 tau,
        int256 inv
    ) internal pure returns (uint256 R_x) {
        // Short circuits because tau != 0 is more likely.
        if (tau != 0) {
            uint256 sec;
            assembly {
                sec := div(mul(tau, ONE), YEAR) // Unit math: YEAR * SCALAR / YEAR = SCALAR.
            }

            uint256 sdr = sec.sqrt(); // √τ.
            assembly {
                sdr := mul(sdr, HALF_SCALAR) // Unit math: HALF_SCALAR * HALF_SCALAR = SCALAR.
                sdr := div(mul(vol, sdr), ONE) // σ√τ.
            }

            int256 phi;
            assembly {
                phi := sdiv(mul(add(R_y, inv), ONE), stk) // (y + k) / K.
            }

            if (phi < 0) revert OOB(); // Negative input for `ppf` is invalid.
            if (phi > ONE) revert OOB();
            if (phi == ONE) return 0; // `x = 1 - Φ(Φ⁻¹( 1 ) + σ√τ)` simplifies to  `x = 0`.
            if (phi == 0) return WAD; // `x = 1 - Φ(Φ⁻¹( 0 ) + σ√τ)` simplifies to `x = 1`.

            phi = phi.ppf(); // Φ⁻¹( (y + k) / K ).

            int256 cdf;
            assembly {
                cdf := add(phi, sdr) // Φ⁻¹( (y + k) / K ) + σ√τ.
            }
            cdf = cdf.cdf(); // Φ(Φ⁻¹( (y + k) / K ) + σ√τ).

            assembly {
                R_x := sub(ONE, cdf)
            }
        } else {
            assembly {
                R_x := sub(ONE, sdiv(mul(add(R_y, inv), ONE), stk))
            }
        }
    }

    /**
     * @notice Computes the invariant of the RMM trading function.
     *
     * @dev Computes `k` in `k = y - KΦ(Φ⁻¹(1-x) - σ√τ)`.
     * Used to validate swaps, the most critical function.
     *
     * @custom:source https://rmm.eth.xyz
     */
    function invariant(
        uint256 R_y,
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (int256 inv) {
        uint256 y = getY(R_x, stk, vol, tau, inv); // `inv` is 0 because we are solving `inv`, aka `k`.
        assembly {
            inv := sub(R_y, y)
        }
    }
}
