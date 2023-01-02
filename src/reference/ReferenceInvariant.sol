// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ReferenceGaussian.sol";

/**
 * @title Invariant of Primitive RMM.
 * @dev `y - KΦ(Φ⁻¹(1-x) - σ√τ) = k`
 */
library Invariant {
    using Gaussian for int256;
    using FixedPointMathLib for uint256;

    uint256 internal constant WAD = 1 ether;
    int256 internal constant ONE = 1 ether;
    int256 internal constant YEAR = 31556952;
    int256 internal constant HALF_SCALAR = 1e9;

    error OOB();

    function getY(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau,
        int256 inv
    ) internal pure returns (uint256 R_y) {
        if (R_x > WAD) revert OOB();
        if (tau < 0) revert OOB(); // todo: add to non-reference?

        if (tau != 0) {
            uint256 sec = tau.divWadDown(uint256(YEAR));
            uint256 sdr = sec.sqrt();
            sdr = sdr * uint256(HALF_SCALAR);
            sdr = vol.mulWadDown(sdr);

            int256 phi = ONE - int256(R_x);
            phi = phi.ppf();

            int256 input = phi - int256(sdr);
            input = input.cdf();

            R_y = uint256(muliWad(int256(stk), input) + inv);
        } else {
            R_y = uint256(muliWad(int256(stk), ONE - int256(R_x)) + inv);
        }
    }

    function invariant(
        uint256 R_y,
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (int256 inv) {
        uint256 y = getY(R_x, stk, vol, tau, inv);
        assembly {
            inv := sub(R_y, y)
        }
    }

    function getX(
        uint256 R_y,
        uint256 stk,
        uint256 vol,
        uint256 tau,
        int256 inv
    ) internal pure returns (uint256 R_x) {
        if (R_y > stk) revert OOB();

        if (tau != 0) {
            uint256 sec = tau.divWadDown(uint256(YEAR));

            uint256 sdr = sec.sqrt();
            sdr = sdr * uint256(HALF_SCALAR);
            sdr = vol.mulWadDown(sdr);

            int256 phi = diviWad(int256(R_y), int256(stk));
            phi = phi.ppf();

            int256 input = phi + int256(sdr);
            input = input.cdf();
            R_x = uint256(ONE - input);
        } else {
            int256 numerator = int256(R_y) + inv;
            int256 denominator = int256(stk);
            R_x = uint256(ONE - diviWad(numerator, denominator));
        }
    }
}
