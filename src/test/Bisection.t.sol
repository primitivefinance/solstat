// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "src/Bisection.sol";

contract TestBisection is Test {
    function fx(int256 x) internal pure returns (int256) {
        return x**3 - x**2 + 2;
    }

    function testBisectionGas() public logs_gas {
        int256 a = -200;
        int256 b = 300;
        int256 actual = Bisection.bisection(a, b, 1, int256(10), fx);
    }

    function testBisection() public {
        int256 a = -200;
        int256 b = 300;
        int256 actual = Bisection.bisection(a, b, 1, int256(10), fx);
        int256 expected = -1;
        emit log_int(actual);
        assertEq(actual, expected);
    }
}
