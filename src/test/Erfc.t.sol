// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestErfc is Test {
    function testFuzz_erfc_ReturnsTwoWhenInputIsTooLow(int256 x) public {
        vm.assume(x <= Gaussian.ERFC_DOMAIN_LOWER);

        // TODO: Investigate why the error selector is 0x4d2d75b1
        // instead of 0x35278d12
        int256 y = Gaussian.erfc(x);
        assertEq(y, int256(2 ether), "erfc-not-two");
    }

    function testFuzz_erfc_ReturnsZeroWhenInputIsTooHigh(int256 x) public {
        vm.assume(x >= Gaussian.ERFC_DOMAIN_UPPER);
        int256 y = Gaussian.erfc(x);
        assertEq(y, 0, "erfc-not-zero");
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

    // todo: fix these tests!! @clemlak
    /* function testDiff_erfc(int256 x) public {
        vm.assume(x < 1999999999999999998000000000000000002);
        vm.assume(x > -1999999999999999998000000000000000002);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "erfc";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        uint256 ref = abi.decode(res, (uint256));
        int256 y = Gaussian.erfc(x);
        // Results have a 0.0001% difference
        assertApproxEqRel(ref, uint256(y), 0.000001 ether);
    } */
}
