// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/Gaussian.sol";

contract TestGaussian is Test {
    function fx(int256 x) internal pure returns (int256) {
        return x**3 - x**2 + 2;
    }

    function erfc(int256 input) public pure returns (int256) {
        return Gaussian.erfc(input);
    }

    function testGaussian() public {
        int256 a = Gaussian.erfc(-1);
        emit log_int(a);
    }
}
