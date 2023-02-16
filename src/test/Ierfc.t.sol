// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestIErfc is Test {
    function testFuzz_ierfc_RevertWhenInputIsOutOfBounds(int256 x) public {
        vm.assume(x < 0 || x > 2 ether);
        vm.expectRevert(Gaussian.OutOfBounds.selector);
        int256 y = Gaussian.ierfc(x);
    }

    function testDiff_erfc(int256 x) public {
        vm.assume(x < 1999999999999999998000000000000000002);
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
