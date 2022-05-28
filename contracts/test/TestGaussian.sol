// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Gaussian.sol";

contract TestGaussian {
    function erfc(int256 input) public view returns (int256) {
        return Gaussian.erfc(input);
    }

    function cdf(int256 input) public view returns (int256) {
        return Gaussian.cdf(input);
    }

    function ierfc(int256 input) public view returns (int256) {
        return Gaussian.ierfc(input);
    }

    function ppf(int256 input) public view returns (int256) {
        return Gaussian.ppf(input);
    }
}
