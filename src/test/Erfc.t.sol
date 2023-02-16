// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestErfc is Test {
    function testFuzz_erfc_RevertWhenInputIsTooLow(int256 x) public {
        vm.assume(x <= -1999999999999999998000000000000000002);

        // TODO: Investigate why the error selector is 0x4d2d75b1
        // instead of 0x35278d12
        vm.expectRevert();
        int256 y = Gaussian.erfc(x);
        y;
    }

    function testFuzz_erfc_RevertWhenInputIsTooHigh(int256 x) public {
        vm.assume(x > 1999999999999999998000000000000000002);
        vm.expectRevert(Gaussian.Overflow.selector);
        int256 y = Gaussian.erfc(x);
        y;
    }

    // TODO: Fix this test
    function testFuzz_erfc_RevertWhenInputLacksPrecision(int256 x) public {
        vm.assume(x > 1999999999999999998000000000000000002);
        vm.expectRevert(Gaussian.Overflow.selector);
        int256 y = Gaussian.erfc(x);
        y;
    }

    function testFuzz_erfc_NegativeInputIsBounded(int256 x) public {
        vm.assume(x > -1999999999999999998000000000000000002);
        vm.assume(x < -0.0000001 ether);
        int256 y = Gaussian.erfc(x);
        assertGe(y, 1 ether);
        assertLe(y, 2 ether);
    }

    function testFuzz_erfc_PositiveInputIsBounded(int256 x) public {
        vm.assume(x > 0.0000001 ether);
        vm.assume(x < 1999999999999999998000000000000000002);
        int256 y = Gaussian.erfc(x);
        assertGe(y, 0 ether);
        assertLe(y, 1 ether);
    }

    function test_erfc_zero_input_returns_one() public {
        assertEq(Gaussian.erfc(0), 1 ether);
    }

    function testDiff_erfc_positive(int256 x) public {
        vm.assume(x > 0.0000001 ether);
        vm.assume(x < 1999999999999999998000000000000000002);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "erfc";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        uint256 ref = abi.decode(res, (uint256));
        int256 y = Gaussian.erfc(x);
        // Results have a 0.000000105538072456% difference
        assertApproxEqAbs(ref, uint256(y), 105538072456);
    }

    function testDiff_erfc_negative(int256 x) public {
        vm.assume(x < 0.0000001 ether);
        vm.assume(x > -1999999999999999998000000000000000002);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "erfc";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        uint256 ref = abi.decode(res, (uint256));
        int256 y = Gaussian.erfc(x);
        // Results have a 0.000000105538072456% difference
        assertApproxEqAbs(ref, uint256(y), 105538072456);
    }
}
