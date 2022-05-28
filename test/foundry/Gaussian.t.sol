// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../../contracts/Gaussian.sol";

contract TestGaussian is Test {
    function fx(int256 x) internal pure returns (int256) {
        return x**3 - x**2 + 2;
    }

    function erfc(int256 input) public view returns (int256) {
        return Gaussian.erfc(input);
    }

    function testERFCGas() public logs_gas {
        int256 actual = Gaussian.erfc(-1);
    }

    function testERFC() public {
        int256 actual = Gaussian.erfc(-1e18);
        int256 expected = 1842700787760006725;
        emit log_int(actual);
        assertEq(actual, expected);
    }

    function testIERFCGas() public logs_gas {
        int256 actual = Gaussian.ierfc(5e17);
    }

    function testCDFGas() public logs_gas {
        int256 actual = Gaussian.cdf(-5e17);
    }

    function testPPFGas() public logs_gas {
        int256 actual = Gaussian.ppf(5e17);
    }
}
