// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title Bisection Root Finding Algorithm.
 * @author alexangelj
 * @dev Ignored by prettier formatting.
 */
library Bisection {
    /**
     * @notice Bisection root finding algorithm.
     * @param ain Initial value greater than root. (To the left of).
     * @param bin Initial value less than root. (To the right of).
     * @param eps Error of the root computed compared to actual root.
     * @param max Maximum number of iterations before exiting the loop.
     * @param fx  Function to find the root of such that f(x) = 0.
     * @return root Solution within error of `eps` to f(x) = 0.
     * @custom:source https://en.wikipedia.org/wiki/Bisection_method
     */
    function bisection(
        int256 ain,
        int256 bin,
        int256 eps,
        int256 max,
        function(int256) pure returns (int256) fx
    ) internal pure returns (int256 root) {
        // Chosen `a` and `b` are incorrect.
        // False if ain * bin < 0, !(ain * bin < 0).
        int256  fxa = fx(ain);
        int256  fxb = fx(bin);
        assembly { if   iszero(slt(mul(fxa, fxb), 0)) { revert(0, 0) } }

        int256  dif;
        int256  itr;
        assembly     {  dif := sub(bin, ain)          } // Are we getting closer to epsilon?

        do {
            assembly { root := sdiv(add(ain, bin), 2) } // root = a + b / 2

            int256 fxr =  fx(root);
            if    (fxr == 0) break;
            fxa =          fx(ain);

            assembly {
                switch slt(mul(fxr, fxa), 0)            // Decide which side to repeat, `a` or `b`.
                case 1       { bin := root }            // 1 if fxr * fxa < 0
                case 0       { ain := root }            // else 0
                itr :=           add(itr, 1)            // Increment iterator.
            }

        } while    (dif >= eps && itr < max);
    }
}
