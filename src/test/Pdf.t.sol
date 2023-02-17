// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestPdf is Test {
    function testDiff_pdf(int256 x) public {
        // vm.assume(x > 0.0000001 ether);
        vm.assume(x > -2828427124746190093171572875253809907);
        vm.assume(x < 2828427124746190093171572875253809907);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "pdf";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        int256 ref = abi.decode(res, (int256));
        int256 y = Gaussian.pdf(x);
        // Results have a 0.0000001% difference
        assertApproxEqAbs(ref, y, 1000000);
    }
}
