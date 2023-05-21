// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../Ndtri.sol";

/// @dev Hardcoded expected values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
contract TestNdtri is Test {
    int256 constant NDTRI_ACCURACY = 1e18;

    /// @notice Compares two in256 values up to a precision with a base of RAY.
    function assertEqPrecision(int256 a, int256 b, int256 precision, string memory message) internal {
        assertEq(a * precision / RAY, b * precision / RAY, message);
    }

    /// @dev Tests various inputs on the domain [0, 1], where input is a probability between 0 and 1.
    function test_ndtri() public {
        assertEqPrecision(Ndtri.ndtri(RAY / 2), int256(0), NDTRI_ACCURACY, "ndtri-0.5");
        assertEqPrecision(Ndtri.ndtri(RAY / 4), int256(-0.674489750196081743202227014e27), NDTRI_ACCURACY, "ndtri-0.25");
        assertEqPrecision(Ndtri.ndtri(RAY / 8), int256(-1.15034938037600817829676531e27), NDTRI_ACCURACY, "ndtri-0.125");
        assertEqPrecision(
            Ndtri.ndtri(RAY / 16), int256(-1.53412054435254631170839905e27), NDTRI_ACCURACY, "ndtri-0.0625"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY * 77 / 93), int256(0.946122671364591906727098902e27), NDTRI_ACCURACY, "ndtri-0.827956"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY * 11 / 85), int256(-1.1291761577077979287868872e27), NDTRI_ACCURACY, "ndtri-0.129412"
        );
    }

    /// Starting at 1e27, decrements by atleast RAY / NDTRI_ACCURACY = 1e9, since thats the lowest unit
    /// that has precision.
    function test_ndtri_near_one() public {
        int256 decrement = RAY / NDTRI_ACCURACY;
        assertEqPrecision(
            Ndtri.ndtri(RAY - decrement),
            int256(8.75729034878231506388112862e27),
            NDTRI_ACCURACY,
            "ndtri-0.999999999999999999000000000"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e1), int256(8.49379322410959807444471881e27), NDTRI_ACCURACY, "ndtri-1-1e-17"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e2), int256(8.22208221613043561267585878e27), NDTRI_ACCURACY, "ndtri-1-1e-16"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e3), int256(7.94134532617099678096674357e27), NDTRI_ACCURACY, "ndtri-1-1e-15"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e4), int256(7.65062809293526881641896581e27), NDTRI_ACCURACY, "ndtri-1-1e-14"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY - decrement * 1e5), int256(7.34879610280067751753910726e27), NDTRI_ACCURACY, "ndtri-1-1e-13"
        );
    }

    /// @dev Tests the edge case where the input is an integer near zero on the ray scale
    function test_ndtri_near_zero() public {
        assertEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY + 1), -int256(8.7572903487823e27), NDTRI_ACCURACY, "ndtri-1e-18"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e1), -int256(8.493793224109598e27), NDTRI_ACCURACY, "ndtri-1e-17"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e2), -int256(8.2220822161304356e27), NDTRI_ACCURACY, "ndtri-1e-16"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e3), -int256(7.9413453261709968e27), NDTRI_ACCURACY, "ndtri-1e-15"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e4), -int256(7.65062809293526882e27), NDTRI_ACCURACY, "ndtri-1e-14"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY / NDTRI_ACCURACY * 1e5), -int256(7.348796102800677518e27), NDTRI_ACCURACY, "ndtri-1e-13"
        );
    }

    function test_ndtri_far_zero() public {}

    /// @dev Expected `b` values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
    function test_ndtri_near_half() public {
        assertEqPrecision(
            Ndtri.ndtri(RAY * 3 / 5), int256(0.253347103135799798798196181e27), NDTRI_ACCURACY, "ndtri-0.666666"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY * 7 / 12), int256(0.210428394247924723324540643e27), NDTRI_ACCURACY, "ndtri-0.583333"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY * 2 / 3), int256(0.43072729929545749020594039e27), NDTRI_ACCURACY, "ndtri-0.666666"
        );
        assertEqPrecision(
            Ndtri.ndtri(RAY * 5 / 6), int256(0.96742156610170103955040122e27), NDTRI_ACCURACY, "ndtri-0.833333"
        );
    }

    int256 constant UPPER_NDTRI_BOUND = RAY - 1 - 1 - 1; // Bound is RAY - 1, but we want to increase by 1 so need at least 2
    int256 constant LOWER_NDTRI_BOUND = 1 + 1 + 1; // Bound is 1, but we want to decrease by 1, so need at least 2

    /// note: fails strictly at values above abs(1), i.e. a == b
    function testFuzz_ndtri_monotonically_increasing(int256 x) public {
        x = bound(x, LOWER_NDTRI_BOUND, UPPER_NDTRI_BOUND);

        int256 a = Ndtri.ndtri(x);
        int256 b = Ndtri.ndtri(x + 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a <= b, "ndtri-monotonically-increasing"); // note: not strict?
    }

    /// note: fails strictly at values above abs(1), i.e. a == b
    function testFuzz_ndtri_monotonically_decreasing(int256 x) public {
        x = bound(x, LOWER_NDTRI_BOUND, UPPER_NDTRI_BOUND);

        int256 a = Ndtri.ndtri(x);
        int256 b = Ndtri.ndtri(x - 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a >= b, "ndtri-monotonically-decreasing"); // note: not strict?
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
