// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";
import {Gaussian as Ref} from "../reference/ReferenceGaussian.sol";

int256 constant HIGH = int256(10 ether);
int256 constant LOW = -int256(10 ether);

// 1e18 == 100%
uint256 constant CDF_ERROR_REL = 0.0000001 ether; // 0.0000001 ether = 0.00001%

contract TestGaussian is Test {
    /// @dev https://keisan.casio.com/calculator
    function test_cdf() public {
        assertApproxEqRel(
            Ref.cdf(1 ether),
            int256(0.841344746068542949 ether),
            CDF_ERROR_REL,
            "cdf-1"
        );
        assertApproxEqRel(
            Ref.cdf(1.5 ether),
            int256(0.933192798731141934 ether),
            CDF_ERROR_REL,
            "cdf-1.5"
        );
        assertApproxEqRel(
            Ref.cdf(2 ether),
            int256(0.977249868051820793 ether),
            CDF_ERROR_REL,
            "cdf-2"
        );
        assertApproxEqRel(
            Ref.cdf(10 ether),
            int256(1 ether),
            CDF_ERROR_REL,
            "cdf-10"
        );

        assertApproxEqRel(
            Ref.cdf(0.0000001 ether),
            int256(0.50000003989422804 ether),
            CDF_ERROR_REL,
            "cdf-0.0000001"
        );

        assertApproxEqRel(
            Ref.cdf(0.01 ether),
            int256(0.503989356314631604 ether),
            CDF_ERROR_REL,
            "cdf-0.01"
        );

        // negative
        assertApproxEqRel(
            Ref.cdf(-int256(0.0000001 ether)),
            int256(0.49999996010577196 ether),
            CDF_ERROR_REL,
            "cdf-negative-0.0000001"
        );
        assertApproxEqRel(
            Ref.cdf(-int256(0.1 ether)),
            int256(0.460172162722971019 ether),
            CDF_ERROR_REL,
            "cdf-negative-0.1"
        );
        assertApproxEqRel(
            Ref.cdf(-int256(0.5 ether)),
            int256(0.308537538725986896 ether),
            CDF_ERROR_REL,
            "cdf-negative-0.5"
        );
        assertApproxEqRel(
            Ref.cdf(-int256(0.99 ether)),
            int256(0.161087059510830911 ether),
            CDF_ERROR_REL,
            "cdf-negative-0.99"
        );
        assertApproxEqRel(
            Ref.cdf(-int256(1 ether)),
            int256(0.158655253931457051 ether),
            CDF_ERROR_REL,
            "cdf-negative-1"
        );
        assertApproxEqRel(
            Ref.cdf(-int256(2 ether)),
            int256(0.022750131948179207 ether),
            CDF_ERROR_REL,
            "cdf-negative-2"
        );
    }

    function test_ppf_one_reverts() public {
        vm.expectRevert(Gaussian.Infinity.selector);
        assertApproxEqRel(
            Ref.ppf(1 ether),
            int256(0 ether),
            CDF_ERROR_REL,
            "ppf-1"
        );
    }

    function test_ppf_zero_reverts() public {
        vm.expectRevert(Gaussian.NegativeInfinity.selector);
        assertApproxEqRel(
            Ref.ppf(0 ether),
            int256(0 ether),
            CDF_ERROR_REL,
            "ppf-0"
        );
    }

    function test_ppf() public {
        assertApproxEqRel(
            Ref.ppf(0.5 ether),
            int256(0 ether),
            CDF_ERROR_REL,
            "ppf-0.5"
        );
        assertApproxEqRel(
            Ref.ppf(0.99 ether),
            int256(2.3263478740408411 ether),
            CDF_ERROR_REL,
            "ppf-0.99"
        );
        assertApproxEqRel(
            Ref.ppf(0.01 ether),
            -int256(2.3263478740408411 ether),
            CDF_ERROR_REL,
            "ppf-0.01"
        );
        assertApproxEqRel(
            Ref.ppf(0.999999 ether),
            int256(4.75342430882289895 ether),
            CDF_ERROR_REL,
            "ppf-0.999999"
        );
        assertApproxEqRel(
            Ref.ppf(0.000001 ether),
            -int256(4.753424308822899 ether),
            CDF_ERROR_REL,
            "ppf-0.000001"
        );

        uint256 ppfRelErr = 0.000001 ether; // todo: rel error goes up as input precision increases.
        assertApproxEqRel(
            Ref.ppf(0.3222222 ether),
            -int256(0.461493756180050379 ether),
            ppfRelErr,
            "ppf-0.3222222"
        );
    }

    function testReference_erfc_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        vm.assume(input != 0);
        int256 actual = Gaussian.erfc(input);
        int256 expected = Ref.erfc(input);
        assertEq(actual, expected, "erfc-inequality");
    }

    // todo: investigate, reverts with Infinity() if input is 1 because of rounding down?
    function testReference_ierfc_Equality(int256 input) public {
        vm.assume(input < 2 ether);
        vm.assume(input > 1);
        int256 actual = Gaussian.ierfc(input);
        int256 expected = Ref.ierfc(input);
        assertEq(actual, expected, "ierfc-inequality");
    }

    function testReference_cdf_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        vm.assume(input != 0);
        int256 actual = Gaussian.cdf(input);
        int256 expected = Ref.cdf(input);
        console.logInt(actual);
        console.logInt(expected);
        // assertEq(actual, expected, "cdf-inequality");
        assertApproxEqRel(actual, expected, 0.0015 ether);
    }

    function testReference_pdf_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        int256 actual = Gaussian.pdf(input);
        int256 expected = Ref.pdf(input);
        assertEq(actual, expected, "pdf-inequality");
    }

    function testReference_ppf_Equality(int256 input) public {
        vm.assume(input > 0);
        vm.assume(input < 1 ether);
        int256 actual = Gaussian.ppf(input);
        int256 expected = Ref.ppf(input);
        assertEq(actual, expected, "ppf-inequality");
    }

    function testERFC() public {
        int256 actual = Gaussian.erfc(-1e18);
        int256 expected = 1842700787760006725;
        assertEq(actual, expected, "erfc");
    }

    function testERFCGas() public logs_gas {
        int256 actual = Gaussian.erfc(-1);
        actual;
    }

    function testIERFCGas() public logs_gas {
        int256 actual = Gaussian.ierfc(5e17);
        actual;
    }

    function testCDFGas() public logs_gas {
        int256 actual = Gaussian.cdf(-5e17);
        actual;
    }

    function testPPFGas() public logs_gas {
        int256 actual = Gaussian.ppf(5e17);
        actual;
    }

    function testPDFGas() public logs_gas {
        int256 actual = Gaussian.pdf(5e17);
        actual;
    }

    function testFuzz_ERFC_Bounds_positive(int256 x) public {
        vm.assume(x >= 0 && x < 1999999999999999998000000000000000002);
        int256 y = Gaussian.erfc(x);
        assertLe(y, 2 ether);
        assertGe(y, 0);
    }

    function testFuzz_ERFC_Bounds_negative(int256 x) public {
        vm.assume(x <= 0 && x > -1999999999999999998000000000000000002);
        int256 y = Gaussian.erfc(x);
        assertLe(y, 2 ether);
        assertGe(y, 0);
    }
}
