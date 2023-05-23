// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../Ndtri.sol";
import "../Gaussian.sol";

/// @dev Hardcoded expected values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
contract TestNdtri is Test {
    int256 constant NDTRI_ACCURACY = 1e18;
    uint256 constant MAX_ROUNDING_DELTA = 1;

    /// @notice Compares two in256 values up to a precision with a base of RAY.
    /// @dev IMPORTANT! Asserts `a` and `b` are within 1 wei up to `precision`.
    function assertApproxEqPrecision(int256 a, int256 b, int256 precision, string memory message) internal {
        // Amount to divide by to scale to precision.
        int256 scalar = RAY / precision;

        // Gets the digits passed the precision end point.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(RAY));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(RAY));

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
        a = a * precision / RAY;
        b = b * precision / RAY;

        assertApproxEqAbs(a, b, MAX_ROUNDING_DELTA, message);
    }

    /// @dev Tests various inputs on the domain (0, 1), where input is a probability between 0 and 1.
    function test_ndtri() public {
        assertApproxEqPrecision(Ndtri.ndtri(RAY / 2), int256(0), NDTRI_ACCURACY, "ndtri-0.5");
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / 4), int256(-0.674489750196081743202227014e27), NDTRI_ACCURACY, "ndtri-0.25"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / 8), int256(-1.15034938037600817829676531e27), NDTRI_ACCURACY, "ndtri-0.125"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / 16), int256(-1.53412054435254631170839905e27), NDTRI_ACCURACY, "ndtri-0.0625"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY * 77 / 93), int256(0.946122671364591906727098902e27), NDTRI_ACCURACY, "ndtri-0.827956"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY * 11 / 85), int256(-1.1291761577077979287868872e27), NDTRI_ACCURACY, "ndtri-0.129412"
        );

        assertApproxEqPrecision(
            Ndtri.ndtri(729329433526774616220000000),
            int256(0.610786196335546300516717471e27),
            NDTRI_ACCURACY,
            "ndtri-0.729329"
        );
    }

    /// @dev Starting at 1e27, decrements by atleast RAY / NDTRI_ACCURACY = 1e9, since thats the lowest unit
    /// that has precision.
    /// i.e. x = 1e27 - 1e9 = 0.999999999999999999000000000
    /// @notice Upper bound is: 1 - exp(-2) < x < 1
    function test_ndtri_upper_bound() public {
        int256 decrement = RAY / NDTRI_ACCURACY;
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY - decrement),
            int256(8.75729034878231506388112862e27),
            NDTRI_ACCURACY,
            "ndtri-0.999999999999999999000000000"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e1), int256(8.49379322410959807444471881e27), NDTRI_ACCURACY, "ndtri-1-1e-17"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e2), int256(8.22208221613043561267585878e27), NDTRI_ACCURACY, "ndtri-1-1e-16"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e3), int256(7.94134532617099678096674357e27), NDTRI_ACCURACY, "ndtri-1-1e-15"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e4), int256(7.65062809293526881641896581e27), NDTRI_ACCURACY, "ndtri-1-1e-14"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e5), int256(7.34879610280067751753910726e27), NDTRI_ACCURACY, "ndtri-1-1e-13"
        );
    }

    /// @dev Tests the edge case where the input is an integer near zero on the ray scale
    /// i.e. x = 1e9 = 0.000000000000000001000000000
    /// @notice Lower bound is: 0 < x < exp(-2)
    function test_ndtri_lower_bound() public {
        console.logInt(Gaussian.ppf(1e1));
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY + 1), -int256(8.7572903487823e27), NDTRI_ACCURACY, "ndtri-1e-18"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e1), -int256(8.493793224109598e27), NDTRI_ACCURACY, "ndtri-1e-17"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e2), -int256(8.2220822161304356e27), NDTRI_ACCURACY, "ndtri-1e-16"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e3), -int256(7.9413453261709968e27), NDTRI_ACCURACY, "ndtri-1e-15"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e4), -int256(7.65062809293526882e27), NDTRI_ACCURACY, "ndtri-1e-14"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e5), -int256(7.348796102800677518e27), NDTRI_ACCURACY, "ndtri-1e-13"
        );
    }

    /// @dev Expected `b` values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
    /// i.e. x = 0.5 = 0.500000000000000000000000000
    /// @notice Middle bound is: exp(-2) < x < 1 - exp(-2)
    function test_ndtri_middle_bound() public {
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY * 1 / 4), int256(-0.674489750196081743202227014e27), NDTRI_ACCURACY, "ndtri-0.25"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY * 7 / 12), int256(0.210428394247924723324540643e27), NDTRI_ACCURACY, "ndtri-0.583333..."
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY * 3 / 5), int256(0.253347103135799798798196181e27), NDTRI_ACCURACY, "ndtri-0.6"
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY * 2 / 3), int256(0.43072729929545749020594039e27), NDTRI_ACCURACY, "ndtri-0.666666..."
        );
        assertApproxEqPrecision(
            Ndtri.ndtri(RAY * 3 / 4), int256(0.674489750196081743202227014e27), NDTRI_ACCURACY, "ndtri-0.75"
        );
    }

    int256 constant UPPER_NDTRI_BOUND = RAY - 1 - 1 - 1; // Bound is RAY - 1, but we want to increase by 1 so need at least 2
    int256 constant LOWER_NDTRI_BOUND = 1 + 1 + 1; // Bound is 1, but we want to decrease by 1, so need at least 2

    /// note: not strict!
    /// @dev As x -> 1, ndtri(x) -> inf
    function testFuzz_ndtri_monotonically_increasing(int256 x) public {
        x = bound(x, LOWER_NDTRI_BOUND, UPPER_NDTRI_BOUND);

        int256 a = Ndtri.ndtri(x);
        int256 b = Ndtri.ndtri(x + 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a <= b, "ndtri-monotonically-increasing");
    }

    /// note: not strict!
    /// @dev As x -> 0, ndtri(x) -> -inf
    function testFuzz_ndtri_monotonically_decreasing(int256 x) public {
        x = bound(x, LOWER_NDTRI_BOUND, UPPER_NDTRI_BOUND);

        int256 a = Ndtri.ndtri(x);
        int256 b = Ndtri.ndtri(x - 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a >= b, "ndtri-monotonically-decreasing");
    }

    function test_ndtri_equals_one_reverts() public {
        vm.expectRevert(Ndtri.MaxNumError.selector);
        Ndtri.ndtri(RAY);
    }

    function test_ndtri_gte_one_reverts() public {
        vm.expectRevert(Ndtri.MaxNumError.selector);
        Ndtri.ndtri(RAY + 1);
    }

    function test_ndtri_equals_zero_reverts() public {
        vm.expectRevert(Ndtri.MaxNumError.selector);
        Ndtri.ndtri(0);
    }

    function test_ndtri_lte_zero_reverts() public {
        vm.expectRevert(Ndtri.MaxNumError.selector);
        Ndtri.ndtri(0 - 1);
    }
}
