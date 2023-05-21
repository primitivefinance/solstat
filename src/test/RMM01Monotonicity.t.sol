// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../Ndtr.sol";
import "../Ndtri.sol";

library RMM01 {
    uint256 constant PRECISION = 1e27;
    int256 internal constant YEAR = 31556952;

    /// @dev Input x reserve is out of the bounds [0, 1].
    error InvalidX();

    /// @dev Up to 1E18 precision.
    function getY(
        uint256 x,
        uint256 strikePriceRay,
        uint256 volatilityRay,
        uint256 timeRemainingSeconds,
        int256 currentInvariant
    ) internal view returns (uint256 y) {
        if (x > PRECISION) revert InvalidX();

        if (x == PRECISION) return uint256(currentInvariant);
        if (x == 0) return uint256(int256(strikePriceRay) + currentInvariant);

        if (timeRemainingSeconds == 0) {
            uint256 product = mulfp(strikePriceRay, PRECISION - x);
            y = uint256(int256(product) + currentInvariant);
        } else {
            int256 tauSeconds = divfp(int256(timeRemainingSeconds), YEAR);
            int256 sqrtTau = sqrtfp(tauSeconds); // * 1e18; // sqrt(1e27) gives us a valuew with 1e9 units... so mulfp by 1e18 to get 1e27 units
            logger.logInt(sqrtTau);
            int256 sqrtTauVol = mulfp(int256(volatilityRay), sqrtTau);
            logger.logInt(sqrtTauVol);
            int256 phi = int256(PRECISION) - int256(x);
            logger.logInt(phi);
            int256 inverseCdf = Ndtri.ndtri(phi);
            logger.logInt(inverseCdf);
            int256 input = inverseCdf - sqrtTauVol;
            logger.logInt(input);
            int256 cdf = Ndtr.ndtr(input);
            logger.logInt(cdf);
            int256 product = mulfp(int256(strikePriceRay), cdf);
            y = uint256(product + currentInvariant);
        }

        return y;
    }

    /// @dev Computes `k` in `k = y - KΦ(Φ⁻¹(1-x) - σ√τ)`.
    function invariant(
        uint256 x,
        uint256 y,
        uint256 strikePriceRay,
        uint256 volatilityRay,
        uint256 timeRemainingSeconds,
        int256 currentInvariant
    ) internal view returns (int256) {
        return int256(y) - int256(getY(x, strikePriceRay, volatilityRay, timeRemainingSeconds, currentInvariant));
    }
}

contract TestRMM01Monotonicity is Test {
    /// As x -> 1, y -> 0
    function testFuzz_rmm_montonically_increasing(uint256 x, uint256 v, uint256 t) public {
        x = bound(x, 2, 1e27 - 2); // ray
        v = bound(v, 1, 1e7); // bps
        t = bound(t, 1, 500 days); // seconds

        // scales v up to ray since we bound by a small range in units of bps, since this is a realistic range
        v = v * 1e27 / 1e4; // Divides by BPS units which is 1e4, since 1e4 == 100% == 1.0 == 1e27 ray.

        uint256 strikePriceRay = 1e27; // simple strike price since the domain is large.
        int256 k = 0;

        uint256 y = RMM01.getY(x, strikePriceRay, v, t, k);
        uint256 y2 = RMM01.getY(x + 1, strikePriceRay, v, t, k);
        vm.assume(y > 0);

        console.log("x", x);
        console.log("y", y);
        console.log("x2", x + 1);
        console.log("y2", y2);

        assertTrue(y <= y2, "y <= y2");
    }

    /// As x -> 0, y -> K
    function testFuzz_rmm_montonically_decreasing(uint256 x, uint256 v, uint256 t) public {
        x = bound(x, 2, 1e27 - 2); // ray
        v = bound(v, 1, 1e7); // bps
        t = bound(t, 1, 500 days); // seconds

        // scales v up to ray since we bound by a small range in units of bps, since this is a realistic range
        v = v * 1e27 / 1e4; // Divides by BPS units which is 1e4, since 1e4 == 100% == 1.0 == 1e27 ray.

        uint256 strikePriceRay = 1e27; // simple strike price since the domain is large.
        int256 k = 0;

        uint256 y = RMM01.getY(x, strikePriceRay, v, t, k);
        uint256 y2 = RMM01.getY(x - 1, strikePriceRay, v, t, k);
        vm.assume(y > 0);

        console.log("x", x);
        console.log("y", y);
        console.log("x2", x - 1);
        console.log("y2", y2);

        assertTrue(y2 <= y, "y2 <= y");
    }
}
