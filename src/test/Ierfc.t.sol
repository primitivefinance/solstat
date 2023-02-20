// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestIerfc is Test {
    function testFuzz_ierfc_RevertWhenInputIsOutOfBounds(int256 x) public {
        vm.assume(x < 0 || x > 2 ether);
        vm.expectRevert(Gaussian.OutOfBounds.selector);
        int256 y = Gaussian.ierfc(x);
        y;
    }

    function testDiff_ierfc(int256 x) public {
        vm.assume(x > 0.0000001 ether);
        vm.assume(x < 2 ether);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "ierfc";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        int256 ref = abi.decode(res, (int256));
        int256 y = Gaussian.ierfc(x);

        if (x > 0.9 ether && x < 1.1 ether) {
            // When inputs are very close to 1, we tolerate a larger error
            // 0.15% of difference
            assertApproxEqRel(ref, y, 0.0015 ether);
        } else {
            // 0.00005% of difference
            assertApproxEqRel(ref, y, 0.0000005 ether);
        }
    }
}
