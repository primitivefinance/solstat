// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestIerfc is Test {
    function testFuzz_ierfc_RevertWhenInputIsOutOfBounds(int256 x) public {
        vm.assume(x < 0 || x > 2 ether);
        vm.expectRevert(Gaussian.OutOfBounds.selector);
        int256 y = Gaussian.ierfc(x);
        y;
    }

    function test_ierfc_InputOneWillTriggerInfinity() public {
        vm.expectRevert(Gaussian.Infinity.selector);
        int256 y = Gaussian.ierfc(1);
        console.logInt(y);
    }

    function test_ierfc_ZeroTriggersInfinity() public {
        vm.expectRevert(Gaussian.Infinity.selector);
        int256 y = Gaussian.ierfc(0);
        y;
    }

    function test_ierfc_TwoTriggersNegativeInfinity() public {
        vm.expectRevert(Gaussian.NegativeInfinity.selector);
        int256 y = Gaussian.ierfc(2 ether);
        y;
    }

    // todo: fix these tests!! @clemlak
    /* function testDiff_ierfc(int64 x) public {
        vm.assume(x > 0.00001 ether);
        vm.assume(x < 2 ether);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "ierfc";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        int256 ref = abi.decode(res, (int256));
        int256 y = Gaussian.ierfc(int256(x));

        // When inputs are very close to 1, we tolerate a larger error
        if (x > 0.99 ether && x < 1.05 ether) {
            // 0.15% of difference
            assertApproxEqRel(ref, y, 0.0015 ether);
        } else {
            // 0.0003% of difference
            assertApproxEqRel(ref, y, 0.000003 ether);
        }
    } */
}
