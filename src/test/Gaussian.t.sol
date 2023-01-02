// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "src/Gaussian.sol";
import {Gaussian as Ref} from "src/reference/ReferenceGaussian.sol";

int256 constant HIGH = int256(10 ether);
int256 constant LOW = -int256(10 ether);

contract TestGaussian is Test {
    function erfc(int256 input) public pure returns (int256) {
        return Gaussian.erfc(input);
    }

    function testReference_erfc_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        int256 actual = Gaussian.erfc(input);
        int256 expected = Ref.erfc(input);
        assertEq(actual, expected, "erfc-inequality");
    }

    // todo: investigate, reverts with Infinity() if input is 1 because of rounding down?
    function testReference_ierfc_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        vm.assume(input != 1);
        int256 actual = Gaussian.ierfc(input);
        int256 expected = Ref.ierfc(input);
        assertEq(actual, expected, "ierfc-inequality");
    }

    function testReference_cdf_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        int256 actual = Gaussian.cdf(input);
        int256 expected = Ref.cdf(input);
        assertEq(actual, expected, "cdf-inequality");
    }

    function testReference_pdf_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        int256 actual = Gaussian.pdf(input);
        int256 expected = Ref.pdf(input);
        assertEq(actual, expected, "pdf-inequality");
    }

    function testReference_ppf_Equality(int256 input) public {
        vm.assume(input < HIGH);
        vm.assume(input > LOW);
        int256 actual = Gaussian.ppf(input);
        int256 expected = Ref.ppf(input);
        assertEq(actual, expected, "ppf-inequality");
    }

    function testERFCGas() public logs_gas {
        int256 actual = Gaussian.erfc(-1);
        actual;
    }

    function testERFC() public {
        int256 actual = Gaussian.erfc(-1e18);
        int256 expected = 1842700787760006725;
        emit log_int(actual);
        assertEq(actual, expected);
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
}
