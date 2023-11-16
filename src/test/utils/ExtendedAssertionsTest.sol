// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

contract ExtendedAssertionsTest is Test {
    ////////////////
    // Scale      //
    ////////////////
    int256 constant SCALE = 1e27;
    uint256 constant DESIRED_PRECISION = 1e18;
    uint256 constant DESIRED_PRECISION_SCALAR = 1e9; // Desired precision is 1e18, therefore scalar is 1e27 / 1e18 = 1e9

    ////////////////
    // Accuracy   //
    ////////////////
    int256 constant NDTR_ACCURACY = 1e18;
    int256 constant NDTRI_ACCURACY = 1e18;

    ////////////////
    // ApproxEq   //
    ////////////////
    uint256 constant MAX_ROUNDING_DELTA = 1;

    ////////////////
    // Functions  //
    ////////////////

    /// @notice Compares two in256 values up to a precision with a base of SCALE.
    /// @dev IMPORTANT! Asserts `a` and `b` are within 1 wei up to `precision`.
    function assertApproxEqPrecision(uint256 a, uint256 b, uint256 precision, string memory message) internal {
        // Amount to divide by to scale to precision.
        uint256 scalar = uint256(SCALE) / precision;

        // Gets the digits passed the precision end point.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(SCALE));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(SCALE));

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
        a = a * precision / uint256(SCALE);
        b = b * precision / uint256(SCALE);

        assertApproxEqAbs(a, b, MAX_ROUNDING_DELTA, message);
    }

    /// @notice Compares two in256 values up to a precision with a base of SCALE.
    /// @dev IMPORTANT! Asserts `a` and `b` are within 1 wei up to `precision`.
    function assertApproxEqPrecision(int256 a, int256 b, int256 precision, string memory message) internal {
        // Amount to divide by to scale to precision.
        int256 scalar = SCALE / precision;

        // Gets the digits passed the precision end point.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(SCALE));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(SCALE));

        // For debugging...
        if (false) {
            console.log("===== RAW AMOUNTS =====");
            console.logInt(a);
            console.logInt(b);

            console.log("===== SCALED AMOUNTS =====");
            console.logInt(a / scalar);
            console.logInt(b / scalar);

            console.log("===== REMAINDERS =====");
            console.log("remainder0", remainder0);
            console.log("remainder1", remainder1);
        }

        // Converts units to precision.
        a = a * precision / SCALE;
        b = b * precision / SCALE;

        assertApproxEqAbs(a, b, MAX_ROUNDING_DELTA, message);
    }

    /// @dev Asserts `a` is greater than or equal to `b` up to `precision` decimal places.
    /// @param a The expected larger value.
    /// @param b The expected smaller value.
    /// @param precision The number of decimal places to check.
    /// @param message The message to display if the assertion fails.
    function assertGtePrecisionNotStrict(uint256 a, uint256 b, uint256 precision, string memory message) internal {
        // Amount to divide by to scale to precision.
        uint256 scalar = uint256(SCALE) / precision;

        // Quantities beyond the radix point at `precision`. These values are truncated before being checked in this assertion.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(SCALE));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(SCALE));

        // For debugging...
        if (false) {
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
        uint256 scalar = uint256(SCALE) / precision;

        // Quantities beyond the radix point at `precision`. These values are truncated before being checked in this assertion.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(SCALE));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(SCALE));

        // For debugging...
        if (false) {
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
}
