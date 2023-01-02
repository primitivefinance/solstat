// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Units.sol";
import "./ReferenceGaussian.sol";
import "solmate/utils/FixedPointMathLib.sol";

/**
 * @title Invariant of Primitive RMM.
 * @dev `y - KΦ(Φ⁻¹(1-x) - σ√τ) = k`
 */
library Invariant {
    using Gaussian for int256;

    int256 internal constant YEAR = 31556952;
    int256 internal constant ONE = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;

    struct Args {
        int256 x;
        int256 K;
        int256 o;
        int256 t;
    }

    function getY(Args memory args) internal view returns (int256 y) {
        y = getY(args.x, args.K, args.o, args.t);
    }

    error Bad();

    function getY(
        int256 x,
        int256 K,
        int256 o,
        int256 t
    ) internal view returns (int256 y) {
        if (t < 0) revert Bad();
        if (t != 0) {
            int256 sec = diviWad(t, YEAR);
            int256 vol = int256(FixedPointMathLib.sqrt(uint256(sec)));
            assembly {
                vol := mul(vol, HALF_SCALAR)
            }

            vol = muliWad(o, vol);

            int256 phi = (ONE - x).ppf();
            int256 input = phi - vol;
            y = muliWad(K, input.cdf());
        } else {
            y = muliWad(K, ONE - x);
        }
    }

    function invariant(Args memory args, int256 y)
        internal
        view
        returns (int256 k)
    {
        k = invariant(y, args.x, args.K, args.o, args.t);
    }

    function invariant(
        int256 y,
        int256 x,
        int256 K,
        int256 o,
        int256 t
    ) internal view returns (int256 k) {
        int256 y0 = getY(x, K, o, t);
        assembly {
            k := sub(y, y0)
        }
    }

    function getX(
        int256 y,
        int256 K,
        int256 o,
        int256 t
    ) internal view returns (int256 x) {
        int256 sec = diviWad(t, YEAR);
        int256 vol = int256(FixedPointMathLib.sqrt(uint256(sec)));
        assembly {
            vol := mul(vol, HALF_SCALAR)
        }

        vol = muliWad(o, vol);
        int256 phi = diviWad(y, K).ppf();
        int256 input = phi + vol;
        x = ONE - input.cdf();
    }
}
