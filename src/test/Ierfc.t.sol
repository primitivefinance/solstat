// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestIErfc is Test {
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
        // Results have a 0.000041915704014722% difference
        assertApproxEqAbs(ref, y, 41915704014722);
    }
}
