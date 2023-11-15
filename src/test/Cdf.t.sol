// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";

contract TestCdf is Test {
// todo: fix these tests!! @clemlak
/* function testDiff_cdf(int256 x) public {
        vm.assume(x > -2828427124746190093171572875253809907);
        vm.assume(x < 2828427124746190093171572875253809907);
        string[] memory inputs = new string[](3);
        inputs[0] = "./gaussian";
        inputs[1] = "cdf";
        inputs[2] = vm.toString(x);
        bytes memory res = vm.ffi(inputs);
        uint256 ref = abi.decode(res, (uint256));
        int256 y = Gaussian.cdf(x);

        // When outputs are very small, we tolerate a larger error
        if (ref < 1_000_000_000 && y < 1_000_000_000) {
            // 0.1% of difference
            assertApproxEqRel(ref, uint256(y), 0.001 ether);
        } else {
            // 0.00005% of difference
            assertApproxEqRel(ref, uint256(y), 0.0000005 ether);
        }
    } */
}
