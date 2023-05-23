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

    uint256 constant MAX_ROUNDING_DELTA = 1;
    uint256 constant DESIRED_PRECISION = 1e18;
    uint256 constant DESIRED_PRECISION_SCALAR = 1e9; // Desired precision is 1e18, therefore scalar is 1e27 / 1e18 = 1e9

    /// @notice Compares two in256 values up to a precision with a base of RAY.
    /// @dev IMPORTANT! Asserts `a` and `b` are within 1 wei up to `precision`.
    function assertApproxEqPrecision(uint256 a, uint256 b, uint256 precision, string memory message) internal {
        // Amount to divide by to scale to precision.
        uint256 scalar = uint256(RAY) / precision;

        // Gets the digits passed the precision end point.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(RAY));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(RAY));

        // For debugging...
        if (false) {
            console.log("===== RAW AMOUNTS =====");
            console.log("a", a);
            console.log("b", b);

            console.log("===== SCALED AMOUNTS =====");
            console.log("a / scalar", a / scalar);
            console.log("b / scalar", b / scalar);

            console.log("===== REMAINDERS =====");
            console.log("remainder0", remainder0);
            console.log("remainder1", remainder1);
        }

        // Converts units to precision.
        a = a * precision / uint256(RAY);
        b = b * precision / uint256(RAY);

        assertApproxEqAbs(a, b, MAX_ROUNDING_DELTA, message);
    }

    /// @dev Asserts `a` is greater than or equal to `b` up to `precision` decimal places.
    /// @param a The expected larger value.
    /// @param b The expected smaller value.
    /// @param precision The number of decimal places to check.
    /// @param message The message to display if the assertion fails.
    function assertGtePrecisionNotStrict(uint256 a, uint256 b, uint256 precision, string memory message) internal {
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

        assertTrue(a / scalar >= b / scalar, "a >= b");
    }

    /// @dev Asserts `b` is greater than or equal to `a` up to `precision` decimal places.
    /// @param a The expected smaller value.
    /// @param b The expected larger value.
    /// @param precision The number of decimal places to check.
    /// @param message The message to display if the assertion fails.
    function assertLtePrecisionNotStrict(uint256 a, uint256 b, uint256 precision, string memory message) internal {
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

        assertTrue(a / scalar <= b / scalar, "a <= b");
    }

    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// ("✨✨INVARIANT HAS DECREASING MONOTONICITY✨✨");
    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// As x -> 1, y -> 0
    function testFuzz_getY_montonically_decreasing(uint256 x1, uint256 strike, uint256 v, uint256 t) public {
        x1 = bound(x1, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // ray
        strike = bound(strike, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        v = bound(v, 1, 1e7); // bps
        t = bound(t, 1, 500 days); // seconds

        // scales v up to ray since we bound by a small range in units of bps, since this is a realistic range
        v = v * 1e27 / 1e4; // Divides by BPS units which is 1e4, since 1e4 == 100% == 1.0 == 1e27 ray.

        int256 k = 0; // invariant
        uint256 y1 = RMM01.getY(x1, strike, v, t, k); // x smaller, y larger
        uint256 y2 = RMM01.getY(x1 + 1, strike, v, t, k); // x larger, y smaller
        vm.assume(y1 > 0);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("x2", x1 + 1);
        console.log("y2", y2);

        // As x gets larger, expect y to get smaller.
        // Check that y2 is smaller than y1.
        assertGtePrecisionNotStrict(y1, y2, DESIRED_PRECISION, "y1 >= y2");
    }

    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// ("✨✨INVARIANT HAS INCREASING MONOTONICITY✨✨");
    /// ("✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨");
    /// As x -> 0, y -> K
    function testFuzz_getY_montonically_increasing(uint256 x1, uint256 strike, uint256 v, uint256 t) public {
        x1 = bound(x1, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        strike = bound(strike, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        v = bound(v, 1, 1e7); // bps
        t = bound(t, 1, 500 days); // seconds

        // scales v up to ray since we bound by a small range in units of bps, since this is a realistic range
        v = v * 1e27 / 1e4; // Divides by BPS units which is 1e4, since 1e4 == 100% == 1.0 == 1e27 ray.

        int256 k = 0; // invariant
        uint256 y1 = RMM01.getY(x1, strike, v, t, k); // x is larger, y is smaller
        uint256 y2 = RMM01.getY(x1 - 1, strike, v, t, k); // x is smaller, y is larger
        vm.assume(y1 > 0);

        console.log("x1", x1);
        console.log("y1", y1);
        console.log("x2", x1 - 1);
        console.log("y2", y2);

        // As x gets smaller, expect y to get larger.
        // Check that y1 is smaller than y2.
        assertLtePrecisionNotStrict(y1, y2, DESIRED_PRECISION, "y1 <= y2");
    }

    function testFuzz_getY_input_precision(uint256 x1, uint256 strike, uint256 v, uint256 t) public {
        x1 = bound(x1, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        strike = bound(strike, DESIRED_PRECISION_SCALAR + 1, 1e27 - 2); // bounds between the lowest value on the desired precision scale and the upper bound of the domain.
        v = bound(v, 1, 1e7); // bps
        t = bound(t, 1, 500 days); // seconds

        // scales v up to ray since we bound by a small range in units of bps, since this is a realistic range
        v = v * 1e27 / 1e4; // Divides by BPS units which is 1e4, since 1e4 == 100% == 1.0 == 1e27 ray.

        int256 k = 0; // invariant
        // Assume we want to use `ndtr()` but have an input with WAD units (1E18).
        // The input can be scaled to match the units of 1E27.
        // But do we lose precision in the output?
        uint256 outputWith1E27Input = RMM01.getY(x1, strike, v, t, k);
        x1 = x1 / 1e9; // Scale down to 1E18.
        x1 = x1 * 1e9; // Scale back up to 1E27, losing all precision past the 1E18 radix point.
        uint256 outputWith1E18Input = RMM01.getY(x1, strike, v, t, k);

        // Asserts that the outputs scaled to 1E18 are equal up to 1E18 precision, regardless of the input precision.
        assertApproxEqPrecision(outputWith1E27Input, outputWith1E18Input, 1e18, "getY-input-precision");
    }
}
