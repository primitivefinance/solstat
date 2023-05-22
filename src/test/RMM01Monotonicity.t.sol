// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../Ndtr.sol";
import "../Ndtri.sol";

/// @dev Non-strict monotonicity at 1E18 precision. Loss of monotonicity beyond 1E18.
library RMM01 {
    uint256 constant PRECISION = 1e27;
    int256 internal constant YEAR = 31556952;

    /// @dev Input x reserve is out of the bounds [0, 1].
    error InvalidX();

    /// @dev Up to 1E18 precision.
    function getY(
        uint256 x,
        uint256 strikePriceRay,
        uint256 volatilityRay,
        uint256 timeRemainingSeconds,
        int256 currentInvariant
    ) internal view returns (uint256 y) {
        if (x > PRECISION) revert InvalidX();

        if (x == PRECISION) return uint256(currentInvariant);
        if (x == 0) return uint256(int256(strikePriceRay) + currentInvariant);

        if (timeRemainingSeconds == 0) {
            uint256 product = mulfp(strikePriceRay, PRECISION - x);
            y = uint256(int256(product) + currentInvariant);
        } else {
            int256 tauSeconds = divfp(int256(timeRemainingSeconds), YEAR);
            int256 sqrtTau = sqrtfp(tauSeconds); // * 1e18; // sqrt(1e27) gives us a valuew with 1e9 units... so mulfp by 1e18 to get 1e27 units
            int256 sqrtTauVol = mulfp(int256(volatilityRay), sqrtTau);
            int256 phi = int256(PRECISION) - int256(x);
            int256 inverseCdf = Ndtri.ndtri(phi);
            int256 input = inverseCdf - sqrtTauVol;
            int256 cdf = Ndtr.ndtr(input);
            int256 product = mulfp(int256(strikePriceRay), cdf);
            y = uint256(product + currentInvariant);
        }

        return y;
    }

    /// @dev Computes `k` in `k = y - KΦ(Φ⁻¹(1-x) - σ√τ)`.
    function invariant(
        uint256 x,
        uint256 y,
        uint256 strikePriceRay,
        uint256 volatilityRay,
        uint256 timeRemainingSeconds,
        int256 currentInvariant
    ) internal view returns (int256) {
        return int256(y) - int256(getY(x, strikePriceRay, volatilityRay, timeRemainingSeconds, currentInvariant));
    }
}

contract TestRMM01Monotonicity is Test {
    bool DEBUG = false;

    uint256 constant DESIRED_PRECISION = 1e18;
    uint256 constant DESIRED_PRECISION_SCALAR = 1e9; // Desired precision is 1e18, therefore scalar is 1e27 / 1e18 = 1e9

    /// @dev Asserts `a` is greater than or equal to `b` up to `precision` decimal places.
    /// @param a The expected larger value.
    /// @param b The expected smaller value.
    /// @param precision The number of decimal places to check.
    /// @param message The message to display if the assertion fails.
    function assertTruePrecisionNotStrictDecreasing(uint256 a, uint256 b, uint256 precision, string memory message)
        internal
    {
        // Amount to divide by to scale to precision.
        uint256 scalar = uint256(RAY) / precision;

        // Quantities beyond the radix point at `precision`. These values are truncated before being checked in this assertion.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(RAY));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(RAY));

        if (DEBUG) {
            console.log("===== RAW AMOUNTS =====");
            console.log("a", a);
            console.log("b", b);

            console.log("===== SCALED AMOUNTS =====");
            console.log("a", a / scalar);
            console.log("b", b / scalar);

            console.log("===== REMAINDERS =====");
            console.log("remainder0", remainder0);
            console.log("remainder1", remainder1);
        }

        assertTrue(b / scalar <= a / scalar, "b <= a");
    }

    /// @dev Asserts `b` is greater than or equal to `a` up to `precision` decimal places.
    /// @param a The expected smaller value.
    /// @param b The expected larger value.
    /// @param precision The number of decimal places to check.
    /// @param message The message to display if the assertion fails.
    function assertTruePrecisionNotStrictIncreasing(uint256 a, uint256 b, uint256 precision, string memory message)
        internal
    {
        // Amount to divide by to scale to precision.
        uint256 scalar = uint256(RAY) / precision;

        // Quantities beyond the radix point at `precision`. These values are truncated before being checked in this assertion.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(RAY));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(RAY));

        if (DEBUG) {
            console.log("===== RAW AMOUNTS =====");
            console.log("a", a);
            console.log("b", b);

            console.log("===== SCALED AMOUNTS =====");
            console.log("a", a / scalar);
            console.log("b", b / scalar);

            console.log("===== REMAINDERS =====");
            console.log("remainder0", remainder0);
            console.log("remainder1", remainder1);
        }

        assertTrue(b / scalar >= a / scalar, "b >= a");
    }

    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// ("✨✨INVARIANT HAS INCREASING MONOTONICITY✨✨");
    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// As x -> 1, y -> 0
    function testFuzz_rmm_montonically_increasing(uint256 x1, uint256 strike, uint256 v, uint256 t) public {
        x1 = bound(x1, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // ray
        strike = bound(strike, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        v = bound(v, 1, 1e7); // bps
        t = bound(t, 1, 500 days); // seconds

        // scales v up to ray since we bound by a small range in units of bps, since this is a realistic range
        v = v * 1e27 / 1e4; // Divides by BPS units which is 1e4, since 1e4 == 100% == 1.0 == 1e27 ray.

        int256 k = 0; // invariant
        uint256 y1 = RMM01.getY(x1, strike, v, t, k);
        uint256 y2 = RMM01.getY(x1 + 1, strike, v, t, k);
        vm.assume(y1 > 0);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("x2", x1 + 1);
        console.log("y2", y2);

        // Expect y1 is smaller & y2 is larger, or equal.
        assertTruePrecisionNotStrictIncreasing(y1, y2, DESIRED_PRECISION, "y2 <= y1");
    }

    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// ("✨✨INVARIANT HAS DECREASING MONOTONICITY✨✨");
    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// As x -> 0, y -> K
    function testFuzz_rmm_montonically_decreasing(uint256 x1, uint256 strike, uint256 v, uint256 t) public {
        x1 = bound(x1, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        strike = bound(strike, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        v = bound(v, 1, 1e7); // bps
        t = bound(t, 1, 500 days); // seconds

        // scales v up to ray since we bound by a small range in units of bps, since this is a realistic range
        v = v * 1e27 / 1e4; // Divides by BPS units which is 1e4, since 1e4 == 100% == 1.0 == 1e27 ray.

        int256 k = 0; // invariant
        uint256 y1 = RMM01.getY(x1, strike, v, t, k);
        uint256 y2 = RMM01.getY(x1 - 1, strike, v, t, k);
        vm.assume(y1 > 0);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("x2", x1 - 1);
        console.log("y2", y2);

        // Expect y1 is larger & y2 is smaller, or equal.
        assertTruePrecisionNotStrictDecreasing(y1, y2, DESIRED_PRECISION, "y2 <= y1");
    }
}
