// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestCdf is Test {
    function testDiff_cdf(int256 x) public {
        vm.assume(x > -2828427124746190093171572875253809907);
        vm.assume(x < 2828427124746190093171572875253809907);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "cdf";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        int256 ref = abi.decode(res, (int256));
        int256 y = Gaussian.cdf(x);
        // Results have a 0.000000133246208079% difference
        assertApproxEqRel(ref, y, 0.000000133246208079 ether);
    }
}
