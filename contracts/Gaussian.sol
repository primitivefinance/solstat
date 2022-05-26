// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./GaussianConstants.sol";

/**
 * @title Gaussian Math Library
 * @author alexangelj
 * @dev Models the normal distribution.
 * @custom:coauthor
 * @custom:source Inspired by https://github.com/errcw/gaussian.
 */
library Gaussian {
    struct Model {
        uint256 mean;
        uint256 variance;
    }

    /**
     * @notice Approximation of the Complimentary Error Function.
     * @dev
     * @custom:epsilon Fractional error less than 1.2e-7.
     * @custom:source Numerical Recipes in C 2e p221
     */
    function erfc(Model memory model, Fixed18 input)
        internal
        pure
        returns (uint256 output)
    {
        output = GaussianConstants.ONE;
    }

    /**
     * @notice Approximation of the Imaginary Complimentary Error Function.
     * @dev
     * @custom:source Numerical Recipes 3e p265.
     */
    function ierfc() internal pure returns (uint256) {}

    /**
     * @notice Approximation of the Cumulative Distribution Function.
     * @dev
     * @custom:source
     */
    function cdf() internal pure returns (uint256) {}

    /**
     * @notice Approximation of the Probability Density Function.
     * @dev
     * @custom:source
     */
    function pdf() internal pure returns (uint256) {}

    /**
     * @notice Approximation of the Percent Point Function.
     * @dev
     * @custom:source
     */
    function ppf() internal pure returns (uint256) {}
}
