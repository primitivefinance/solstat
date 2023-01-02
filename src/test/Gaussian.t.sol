// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "src/Gaussian.sol";

contract TestGaussian is Test {
    function erfc(int256 input) public pure returns (int256) {
        return Gaussian.erfc(input);
    }

    function testERFCGas() public logs_gas {
        int256 actual = Gaussian.erfc(-1);
        actual;
    }

    function testERFC() public {
        int256 actual = Gaussian.erfc(-1e18);
        int256 expected = 1842700787760006725;
        emit log_int(actual);
        assertEq(actual, expected);
    }

    function testIERFCGas() public logs_gas {
        int256 actual = Gaussian.ierfc(5e17);
        actual;
    }

    function testCDFGas() public logs_gas {
        int256 actual = Gaussian.cdf(-5e17);
        actual;
    }

    function testPPFGas() public logs_gas {
        int256 actual = Gaussian.ppf(5e17);
        actual;
    }

    function testPDFGas() public logs_gas {
        int256 actual = Gaussian.pdf(5e17);
        actual;
    }
}
