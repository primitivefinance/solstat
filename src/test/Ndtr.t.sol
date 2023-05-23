// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../Ndtr.sol";
import "../Gaussian.sol";

/// @dev Hardcoded expected values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
contract TestNdtr is Test {
    uint256 constant MAX_ROUNDING_DELTA = 1;
    int256 constant NDTR_ACCURACY = 1e18;

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

    function test_ndtr() public {
        assertApproxEqPrecision(Ndtr.ndtr(RAY), int256(0.841344746068542948585232545e27), NDTR_ACCURACY, "ndtr-1");
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY * 15 / 10), int256(0.933192798731141934488289354e27), NDTR_ACCURACY, "ndtr-1.5"
        );
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 2), int256(0.977249868051820792947945109e27), NDTR_ACCURACY, "ndtr-2");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 10), int256(0.999999999999999999999999999e27), NDTR_ACCURACY, "ndtr-10");
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY / 10000000), int256(0.500000039894228040143796598e27), NDTR_ACCURACY, "ndtr-0.0000001"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY / 100), int256(0.503989356314631603924543868e27), NDTR_ACCURACY, "ndtr-0.01"
        );
        // negative
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / 10000000), int256(0.499999960105771959856203402e27), NDTR_ACCURACY, "ndtr--0.0000001"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / 100), int256(0.496010643685368396075456132e27), NDTR_ACCURACY, "ndtr--0.01"
        );
        // 0
        assertApproxEqPrecision(Ndtr.ndtr(0), int256(0.5e27), NDTR_ACCURACY, "ndtr-0");
        // random values at scale of 1e27
        assertApproxEqPrecision(
            Ndtr.ndtr(0.123456789e27), int256(0.5491273050781420888711e27), NDTR_ACCURACY, "ndtr-0.123456789"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(0.987654321e27), int256(0.83833901356624443490786e27), NDTR_ACCURACY, "ndtr-0.987654321"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-0.123456789e27), int256(0.4508726949218579111288e27), NDTR_ACCURACY, "ndtr--0.123456789"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-0.987654321e27), int256(0.16166098643375556509213e27), NDTR_ACCURACY, "ndtr--0.987654321"
        );
    }

    /// @dev Tests the edge case where the input is an integer near zero on the ray scale
    function test_ndtr_near_zero() public {
        assertApproxEqPrecision(Ndtr.ndtr(RAY / NDTR_ACCURACY), int256(0.5e27), NDTR_ACCURACY, "ndtr-1e-18");
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY), int256(0.499999999999999999999999999e27), NDTR_ACCURACY, "ndtr--1e-18"
        );
        assertApproxEqPrecision(Ndtr.ndtr(RAY / NDTR_ACCURACY + 1), int256(0.5e27), NDTR_ACCURACY, "ndtr-1e-18+1");
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY - 1),
            int256(0.499999999999999999999999999e27),
            NDTR_ACCURACY,
            "ndtr--1e-18-1"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e1), int256(0.500000000000000003989422804e27), NDTR_ACCURACY, "ndtr-1e-17"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e1),
            int256(0.499999999999999996010577195e27),
            NDTR_ACCURACY,
            "ndtr--1e-17"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e2), int256(0.50000000000000003989422804e27), NDTR_ACCURACY, "ndtr-1e-16"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e2),
            int256(0.499999999999999960105771959e27),
            NDTR_ACCURACY,
            "ndtr--1e-16"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e3), int256(0.500000000000000398942280401e27), NDTR_ACCURACY, "ndtr-1e-15"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e3),
            int256(0.499999999999999601057719598e27),
            NDTR_ACCURACY,
            "ndtr--1e-15"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e4), int256(0.500000000000003989422804014e27), NDTR_ACCURACY, "ndtr-1e-14"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e4),
            int256(0.499999999999996010577195985e27),
            NDTR_ACCURACY,
            "ndtr--1e-14"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e5), int256(0.500000000000039894228040143e27), NDTR_ACCURACY, "ndtr-1e-13"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e5),
            int256(0.499999999999960105771959856e27),
            NDTR_ACCURACY,
            "ndtr--1e-13"
        );
    }

    function test_ndtr_far_zero() public {
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 2), int256(0.977249868051820792947945109e27), NDTR_ACCURACY, "ndtr-2");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 3), int256(0.998650101968369905473348185e27), NDTR_ACCURACY, "ndtr-3");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 4), int256(0.999968328758166880078746229e27), NDTR_ACCURACY, "ndtr-4");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 5), int256(0.999999713348428120806088326e27), NDTR_ACCURACY, "ndtr-5");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 6), int256(0.999999999013412354962301859e27), NDTR_ACCURACY, "ndtr-6");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 7), int256(0.999999999998720187456114164e27), NDTR_ACCURACY, "ndtr-7");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 8), int256(0.999999999999999377903942572e27), NDTR_ACCURACY, "ndtr-8");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 9), int256(0.999999999999999999887141159e27), NDTR_ACCURACY, "ndtr-9");
        assertApproxEqPrecision(Ndtr.ndtr(RAY * 10), int256(0.999999999999999999887141159e27), NDTR_ACCURACY, "ndtr-10");

        // Negative
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 2), int256(0.022750131948179207200282637e27), NDTR_ACCURACY, "ndtr--2");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 3), int256(0.001349898031630094526651814e27), NDTR_ACCURACY, "ndtr--3");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 4), int256(3.167124183311992125377e22), NDTR_ACCURACY, "ndtr--4");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 5), int256(2.86651571879193911673e20), NDTR_ACCURACY, "ndtr--5");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 6), int256(9.8658764503769814e17), NDTR_ACCURACY, "ndtr--6");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 7), int256(1.279812543885835e15), NDTR_ACCURACY, "ndtr--7");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 8), int256(6.22096057427e11), NDTR_ACCURACY, "ndtr--8");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 9), int256(1.1285884e8), NDTR_ACCURACY, "ndtr--9");
        assertApproxEqPrecision(Ndtr.ndtr(-RAY * 10), int256(7.619e3), NDTR_ACCURACY, "ndtr--10");
    }

    /// @dev Expected `b` values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
    function test_ndtr_near_half() public {
        assertApproxEqPrecision(Ndtr.ndtr(RAY / 2), int256(0.69146246127401310363770461e27), NDTR_ACCURACY, "ndtr-0.5");
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY * 7 / 12), int256(0.720165536400294250547948904e27), NDTR_ACCURACY, "ndtr-0.583333"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY * 2 / 3), int256(0.747507462453077086935938175e27), NDTR_ACCURACY, "ndtr-0.666666"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(RAY * 5 / 6), int256(0.7976716190363569746314664e27), NDTR_ACCURACY, "ndtr-0.833333"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY / 2), int256(0.308537538725986896362295389e27), NDTR_ACCURACY, "ndtr--0.5"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY * 7 / 12), int256(0.279834463599705749452051095e27), NDTR_ACCURACY, "ndtr--0.583333"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY * 2 / 3), int256(0.252492537546922913064061824e27), NDTR_ACCURACY, "ndtr--0.666666"
        );
        assertApproxEqPrecision(
            Ndtr.ndtr(-RAY * 5 / 6), int256(0.202328380963643025368533599e27), NDTR_ACCURACY, "ndtr--0.833333"
        );
    }

    int256 constant UPPER_NDTR_BOUND = 10 * RAY;
    int256 constant LOWER_NDTR_BOUND = -10 * RAY;

    /// note: fails strictly at values above abs(1), i.e. a == b
    /// @dev As x -> inf, y -> 1
    function testFuzz_ndtr_monotonically_increasing(int256 x) public {
        x = bound(x, LOWER_NDTR_BOUND, UPPER_NDTR_BOUND);

        int256 a = Ndtr.ndtr(x);
        int256 b = Ndtr.ndtr(x + 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a <= b, "ndtr-monotonically-increasing"); // note: not strict?
    }

    /// note: fails strictly at values above abs(1), i.e. a == b
    /// @dev As x -> -inf, y -> 0
    function testFuzz_ndtr_monotonically_decreasing(int256 x) public {
        x = bound(x, LOWER_NDTR_BOUND, UPPER_NDTR_BOUND);

        int256 a = Ndtr.ndtr(x);
        int256 b = Ndtr.ndtr(x - 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a >= b, "ndtr-monotonically-decreasing"); // note: not strict?
    }

    /// note: fails strictly at values above abs(1), i.e. a == b
    /// @dev As x -> -2, y -> 2
    function testFuzz_erfc_monotonically_increasing(int256 x) public {
        x = bound(x, LOWER_NDTR_BOUND, UPPER_NDTR_BOUND);

        int256 a = Ndtr.erfc(x);
        int256 b = Ndtr.erfc(x - 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a <= b, "erfc-monotonically-increasing"); // note: not strict?
    }

    /// note: fails strictly at values above abs(1), i.e. a == b
    /// @dev As x -> 2, y -> 0
    function testFuzz_erfc_monotonically_decreasing(int256 x) public {
        vm.assume(x != 0);
        x = bound(x, LOWER_NDTR_BOUND, UPPER_NDTR_BOUND);
        x = absolute(x); // erfc is decreasing for positive values

        int256 a = Ndtr.erfc(x);
        int256 b = Ndtr.erfc(x + 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a >= b, "erfc-monotonically-decreasing"); // note: not strict?
    }

    function testFuzz_erfc_ReturnsTwoWhenInputIsTooLow(int128 x) public {
        vm.assume(x < 0);
        int256 z = -mulfp(x, x);
        vm.assume(z < -RAY_MAXLOG);
        int256 y = Ndtr.erfc(x);
        assertEq(y, int256(RAY_TWO), "erfc-not-two");
    }

    function testFuzz_erfc_ReturnsZeroWhenInputIsTooHigh(int128 x) public {
        vm.assume(x > 0);
        int256 z = -mulfp(x, x);
        vm.assume(z < -RAY_MAXLOG);
        int256 y = Ndtr.erfc(x);
        assertEq(y, 0, "erfc-not-zero");
    }

    /// @dev erfc domain is -2 < 0 < 2, check between (-2, 0)
    function testFuzz_erfc_NegativeInputIsBounded(int256 x) public {
        vm.assume(x > -RAY_TWO); //
        vm.assume(x < -1e9); // smallest unit of precision closest to zero.
        int256 y = Ndtr.erfc(x);
        assertGe(y, RAY);
        assertLe(y, RAY_TWO);
    }

    /// @dev erfc domain is -2 < 0 < 2, check between (0, 2)
    function testFuzz_erfc_PositiveInputIsBounded(int256 x) public {
        vm.assume(x > 1e9);
        vm.assume(x < RAY_TWO);
        int256 y = Ndtr.erfc(x);
        assertGe(y, 0 ether);
        assertLe(y, RAY);
    }

    function test_erfc_zero_input_returns_one() public {
        assertEq(Ndtr.erfc(0), RAY);
    }

    function testFuzz_ndtr_input_precision(int256 x) public {
        x = bound(x, -10e27, 10e27); // Bound between [-10, 10] in units of 1E27.
        vm.assume(absolute(x) > 1e9); // Since we are dividing by 1E9... need to have at least 1 in the input, so x has to be gte 1E9.

        // Assume we want to use `ndtr()` but have an input with WAD units (1E18).
        // The input can be scaled to match the units of 1E27.
        // But do we lose precision in the output?
        int256 outputWith1E27Input = Ndtr.ndtr(x);
        x = x / 1e9; // Scale down to 1E18.
        x = x * 1e9; // Scale back up to 1E27, losing all precision past the 1E18 radix point.
        int256 outputWith1E18Input = Ndtr.ndtr(x);

        // Asserts that the outputs scaled to 1E18 are equal up to 1E18 precision, regardless of the input precision.
        assertApproxEqPrecision(outputWith1E27Input, outputWith1E18Input, 1e18, "ndtr-input-precision");
    }
}
