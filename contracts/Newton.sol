// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title Newton-Raphson Method.
 * @dev Produces successively better approximations to the roots of a "real-valued function".
 * @custom:source https://personal.math.ubc.ca/~pwalls/math-python/roots-optimization/newton/
 */
library Newton {
    /**
     * @notice Uses Newton's method to solve the root of the function `fx` within `maxRuns` with error `epsilon`.
     * @dev Source: https://people.cs.uchicago.edu/~ridg/newna/nalrs.pdf
     * @param  x Initial guess for the solution of f(x) = 0.
     * @param  epsilon Error boundary of the root.
     * @param  fx Function to find the solution of f(x) = 0.
     * @param  dx Derivative of the function `fx`.
     * @return x Computed root, within the `maxRuns` of `fx`.
     */
    /* function compute(
        int256 x,
        int256 epsilon,
        function(int256) pure returns (int256) fx,
        function(int256) pure returns (int256) dx
    ) internal pure returns (int256 y) {
        int256 h = fx(x).div(dx(x));
        assembly {
            y := sub(x, h)
        }
        h = fx(x).div(dx(x));
        assembly {
            y := sub(x, h)
        }
        h = fx(x).div(dx(x));
        assembly {
            y := sub(x, h)
        }
        h = fx(x).div(dx(x));
        assembly {
            y := sub(x, h)
        }
        h = fx(x).div(dx(x));
        assembly {
            y := sub(x, h)
        }

        if (h.abs() < epsilon) revert;

        return x;
    } */
}
