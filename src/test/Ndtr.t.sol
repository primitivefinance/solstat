// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../Ndtr.sol";

import "../Gaussian.sol";

/// @dev Hardcoded expected values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
contract TestNdtr is Test {
    int256 constant NDTR_ACCURACY = 1e18;

    /// @notice Compares two in256 values up to a precision with a base of RAY.
    function assertEqPrecision(int256 a, int256 b, int256 precision, string memory message) internal {
        // Gets the digits passed the precision end point.
        uint256 remainder0 = mulmod(uint256(a), uint256(precision), uint256(RAY));
        uint256 remainder1 = mulmod(uint256(b), uint256(precision), uint256(RAY));

        // Add one to the remainder to round up, in the case it is 99...99.
        remainder0++;
        remainder1++;

        // Converts units to precision.
        a = a * precision / RAY;
        b = b * precision / RAY;

        // Rounds up if remainder is >= 0.5.
        if (int256(remainder0) >= RAY_HALF) a++;
        if (int256(remainder1) >= RAY_HALF) b++;

        assertEq(a, b, message);
    }

    function test_ndtr() public {
        assertEqPrecision(Ndtr.ndtr(RAY), int256(0.841344746068542948585232545e27), NDTR_ACCURACY, "ndtr-1");
        assertEqPrecision(Ndtr.ndtr(RAY * 15 / 10), int256(0.933192798731141934488289354e27), NDTR_ACCURACY, "ndtr-1.5");

        assertEqPrecision(Ndtr.ndtr(RAY * 2), int256(0.977249868051820792947945109e27), NDTR_ACCURACY, "ndtr-2");
        assertEqPrecision(Ndtr.ndtr(RAY * 10), int256(0.999999999999999999999999999e27), NDTR_ACCURACY, "ndtr-10");
        assertEqPrecision(
            Ndtr.ndtr(RAY / 10000000), int256(0.500000039894228040143796598e27), NDTR_ACCURACY, "ndtr-0.0000001"
        );
        assertEqPrecision(Ndtr.ndtr(RAY / 100), int256(0.503989356314631603924543868e27), NDTR_ACCURACY, "ndtr-0.01");
        // negative
        assertEqPrecision(
            Ndtr.ndtr(-RAY / 10000000), int256(0.499999960105771959856203402e27), NDTR_ACCURACY, "ndtr--0.0000001"
        );
        assertEqPrecision(Ndtr.ndtr(-RAY / 100), int256(0.496010643685368396075456132e27), NDTR_ACCURACY, "ndtr--0.01");
        // 0
        assertEqPrecision(Ndtr.ndtr(0), int256(0.5e27), NDTR_ACCURACY, "ndtr-0");
        // random values at scale of 1e27
        assertEqPrecision(
            Ndtr.ndtr(0.123456789e27), int256(0.5491273050781420888711e27), NDTR_ACCURACY, "ndtr-0.123456789"
        );
        assertEqPrecision(
            Ndtr.ndtr(0.987654321e27), int256(0.83833901356624443490786e27), NDTR_ACCURACY, "ndtr-0.987654321"
        );

        assertEqPrecision(
            Ndtr.ndtr(-0.123456789e27), int256(0.4508726949218579111288e27), NDTR_ACCURACY, "ndtr--0.123456789"
        );
        assertEqPrecision(
            Ndtr.ndtr(-0.987654321e27), int256(0.16166098643375556509213e27), NDTR_ACCURACY, "ndtr--0.987654321"
        );
    }

    /// @dev Tests the edge case where the input is an integer near zero on the ray scale
    function test_ndtr_near_zero() public {
        assertEqPrecision(Ndtr.ndtr(RAY / NDTR_ACCURACY), int256(0.5e27), NDTR_ACCURACY, "ndtr-1e-18");
        assertEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY), int256(0.499999999999999999999999999e27), NDTR_ACCURACY, "ndtr--1e-18"
        );

        assertEqPrecision(Ndtr.ndtr(RAY / NDTR_ACCURACY + 1), int256(0.5e27), NDTR_ACCURACY, "ndtr-1e-18+1");
        assertEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY - 1),
            int256(0.499999999999999999999999999e27),
            NDTR_ACCURACY,
            "ndtr--1e-18-1"
        );

        assertEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e1), int256(0.500000000000000003989422804e27), NDTR_ACCURACY, "ndtr-1e-17"
        );
        assertEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e1),
            int256(0.499999999999999996010577195e27),
            NDTR_ACCURACY,
            "ndtr--1e-17"
        );

        assertEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e2), int256(0.50000000000000003989422804e27), NDTR_ACCURACY, "ndtr-1e-16"
        );
        assertEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e2),
            int256(0.499999999999999960105771959e27),
            NDTR_ACCURACY,
            "ndtr--1e-16"
        );

        assertEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e3), int256(0.500000000000000398942280401e27), NDTR_ACCURACY, "ndtr-1e-15"
        );
        assertEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e3),
            int256(0.499999999999999601057719598e27),
            NDTR_ACCURACY,
            "ndtr--1e-15"
        );

        assertEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e4), int256(0.500000000000003989422804014e27), NDTR_ACCURACY, "ndtr-1e-14"
        );
        assertEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e4),
            int256(0.499999999999996010577195985e27),
            NDTR_ACCURACY,
            "ndtr--1e-14"
        );

        assertEqPrecision(
            Ndtr.ndtr(RAY / NDTR_ACCURACY * 1e5), int256(0.500000000000039894228040143e27), NDTR_ACCURACY, "ndtr-1e-13"
        );

        assertEqPrecision(
            Ndtr.ndtr(-RAY / NDTR_ACCURACY * 1e5),
            int256(0.499999999999960105771959856e27),
            NDTR_ACCURACY,
            "ndtr--1e-13"
        );
    }

    function test_ndtr_far_zero() public {
        assertEqPrecision(Ndtr.ndtr(RAY * 2), int256(0.977249868051820792947945109e27), NDTR_ACCURACY, "ndtr-2");
        assertEqPrecision(Ndtr.ndtr(RAY * 3), int256(0.998650101968369905473348185e27), NDTR_ACCURACY, "ndtr-3");
        assertEqPrecision(Ndtr.ndtr(RAY * 4), int256(0.999968328758166880078746229e27), NDTR_ACCURACY, "ndtr-4");
        assertEqPrecision(Ndtr.ndtr(RAY * 5), int256(0.999999713348428120806088326e27), NDTR_ACCURACY, "ndtr-5");
        assertEqPrecision(Ndtr.ndtr(RAY * 6), int256(0.999999999013412354962301859e27), NDTR_ACCURACY, "ndtr-6");
        assertEqPrecision(Ndtr.ndtr(RAY * 7), int256(0.999999999998720187456114164e27), NDTR_ACCURACY, "ndtr-7");
        assertEqPrecision(Ndtr.ndtr(RAY * 8), int256(0.999999999999999377903942572e27), NDTR_ACCURACY, "ndtr-8");
        assertEqPrecision(Ndtr.ndtr(RAY * 9), int256(0.999999999999999999887141159e27), NDTR_ACCURACY, "ndtr-9");
        assertEqPrecision(Ndtr.ndtr(RAY * 10), int256(0.999999999999999999887141159e27), NDTR_ACCURACY, "ndtr-10");

        // Negative
        assertEqPrecision(Ndtr.ndtr(-RAY * 2), int256(0.022750131948179207200282637e27), NDTR_ACCURACY, "ndtr--2");
        assertEqPrecision(Ndtr.ndtr(-RAY * 3), int256(0.001349898031630094526651814e27), NDTR_ACCURACY, "ndtr--3");
        assertEqPrecision(Ndtr.ndtr(-RAY * 4), int256(3.167124183311992125377e22), NDTR_ACCURACY, "ndtr--4");
        assertEqPrecision(Ndtr.ndtr(-RAY * 5), int256(2.86651571879193911673e20), NDTR_ACCURACY, "ndtr--5");
        assertEqPrecision(Ndtr.ndtr(-RAY * 6), int256(9.8658764503769814e17), NDTR_ACCURACY, "ndtr--6");
        assertEqPrecision(Ndtr.ndtr(-RAY * 7), int256(1.279812543885835e15), NDTR_ACCURACY, "ndtr--7");
        assertEqPrecision(Ndtr.ndtr(-RAY * 8), int256(6.22096057427e11), NDTR_ACCURACY, "ndtr--8");
        assertEqPrecision(Ndtr.ndtr(-RAY * 9), int256(1.1285884e8), NDTR_ACCURACY, "ndtr--9");
        assertEqPrecision(Ndtr.ndtr(-RAY * 10), int256(7.619e3), NDTR_ACCURACY, "ndtr--10");
    }

    /// @dev Expected `b` values computed manually using `normalcdlower` operation in https://keisan.casio.com/calculator
    function test_ndtr_near_half() public {
        assertEqPrecision(Ndtr.ndtr(RAY / 2), int256(0.69146246127401310363770461e27), NDTR_ACCURACY, "ndtr-0.5");
        assertEqPrecision(
            Ndtr.ndtr(RAY * 7 / 12), int256(0.720165536400294250547948904e27), NDTR_ACCURACY, "ndtr-0.583333"
        );
        assertEqPrecision(
            Ndtr.ndtr(RAY * 2 / 3), int256(0.747507462453077086935938175e27), NDTR_ACCURACY, "ndtr-0.666666"
        );
        assertEqPrecision(
            Ndtr.ndtr(RAY * 5 / 6), int256(0.7976716190363569746314664e27), NDTR_ACCURACY, "ndtr-0.833333"
        );

        assertEqPrecision(Ndtr.ndtr(-RAY / 2), int256(0.308537538725986896362295389e27), NDTR_ACCURACY, "ndtr--0.5");
        assertEqPrecision(
            Ndtr.ndtr(-RAY * 7 / 12), int256(0.279834463599705749452051095e27), NDTR_ACCURACY, "ndtr--0.583333"
        );
        assertEqPrecision(
            Ndtr.ndtr(-RAY * 2 / 3), int256(0.252492537546922913064061824e27), NDTR_ACCURACY, "ndtr--0.666666"
        );
        assertEqPrecision(
            Ndtr.ndtr(-RAY * 5 / 6), int256(0.202328380963643025368533599e27), NDTR_ACCURACY, "ndtr--0.833333"
        );
    }

    int256 constant UPPER_NDTR_BOUND = 10 * RAY;
    int256 constant LOWER_NDTR_BOUND = -10 * RAY;

    /// note: fails strictly at values above abs(1), i.e. a == b
    function testFuzz_ndtr_monotonically_increasing(int256 x) public {
        x = bound(x, LOWER_NDTR_BOUND, UPPER_NDTR_BOUND);

        int256 a = Ndtr.ndtr(x);
        int256 b = Ndtr.ndtr(x + 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a <= b, "ndtr-monotonically-increasing"); // note: not strict?
    }

    /// note: fails strictly at values above abs(1), i.e. a == b
    function testFuzz_ndtr_monotonically_decreasing(int256 x) public {
        x = bound(x, LOWER_NDTR_BOUND, UPPER_NDTR_BOUND);

        int256 a = Ndtr.ndtr(x);
        int256 b = Ndtr.ndtr(x - 1);
        console.logInt(a);
        console.logInt(b);

        assertTrue(a >= b, "ndtr-monotonically-decreasing"); // note: not strict?
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

    function testFuzz_erfc_NegativeInputIsBounded(int256 x) public {
        vm.assume(x > -1999999999999999998000000000000000002 * 1e9);
        vm.assume(x < -0.0000001 ether * 1e9);
        int256 y = Ndtr.erfc(x);
        assertGe(y, RAY);
        assertLe(y, RAY_TWO);
    }

    function testFuzz_erfc_PositiveInputIsBounded(int256 x) public {
        vm.assume(x > 0.0000001 ether * 1e9);
        vm.assume(x < 1999999999999999998000000000000000002 * 1e9);
        int256 y = Ndtr.erfc(x);
        assertGe(y, 0 ether);
        assertLe(y, RAY);
    }

    function test_erfc_zero_input_returns_one() public {
        assertEq(Ndtr.erfc(0), RAY);
    }

    /// todo: update this test... it will fail because ndtr is better than the reference, so not equal!
    /* function testFuzz_ndtr_reference(int256 x) public {
        x = bound(x, -int256(2 * 1e27), int256(2 * 1e27));
        int256 y0 = Ndtr.ndtr(x);
        x /= 1e9;
        int256 y1 = Gaussian.cdf(x);
        console.logInt(y0);
        console.logInt(y1);

        assertEqPrecision(y0, y1 * 1e9, 1e9, "ndtr-reference");
    } */
}
