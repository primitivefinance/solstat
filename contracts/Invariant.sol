// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./FixedMath.sol";
import "./Gaussian.sol";
import "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";

/**
 * @title Invariant of Primitive RMM.
 * @dev `y - KΦ(Φ⁻¹(1-x) - σ√τ) = k`
 */
library Invariant {
    using Gaussian for int256;
    using FixedMath for int256;
    using FixedPointMathLib for uint256;

    int256 internal constant YEAR = 31556952;
    int256 internal constant ONE = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;

    struct Args {
        uint256 x;
        uint256 K;
        uint256 o;
        uint256 t;
    }

    function getY(Args memory args) internal view returns (uint256 y) {
        y = getY(args.x, args.K, args.o, args.t);
    }

    function getX(Args memory args) internal view returns (uint256 x) {
        x = getX(args.x, args.K, args.o, args.t);
    }

    error Bad();

    function getY(
        uint256 x,
        uint256 K,
        uint256 o,
        uint256 t
    ) internal view returns (uint256 y) {
        if (t < 0) revert Bad();
        if (t != 0) {
            //int256 sec = diviWad(t, YEAR);
            //int256 vol = int256(FixedPointMathLib.sqrt(uint256(sec)));

            int256 sec;
            assembly {
                // Scales amount of seconds to units of `SCALAR`. The `t` must be in units of `YEAR`.
                // For example, if `t` == `YEAR`, `sec` will be `SCALAR`, which is equal to one year.
                sec := sdiv(mul(t, ONE), YEAR)
            }
            int256 vol = sec.sqrt();
            assembly {
                vol := mul(vol, HALF_SCALAR)
                vol := sdiv(mul(o, vol), ONE)
            }
            //vol = muliWad(o, vol);
            int256 phi;
            assembly {
                phi := sub(ONE, x)
            }

            phi = phi.ppf();

            int256 input;
            assembly {
                input := sub(phi, vol)
            }

            input = input.cdf();
            assembly {
                y := sdiv(mul(K, input), ONE)
            }

            //int256 phi = (ONE - x).ppf();
            //int256 input = phi - vol;
            //y = muliWad(K, input.cdf());
        } else {
            //y = muliWad(K, ONE - x);
            assembly {
                // `K` is in SCALAR, ONE - x is in SCALAR, so SCALAR * SCALAR / SCALAR = SCALAR.
                y := sdiv(mul(K, sub(ONE, x)), ONE)
            }
        }
    }

    function invariant(Args memory args, uint256 y)
        internal
        view
        returns (int256 k)
    {
        k = invariant(y, args.x, args.K, args.o, args.t);
    }

    function invariant(
        uint256 y,
        uint256 x,
        uint256 K,
        uint256 o,
        uint256 t
    ) internal view returns (int256 k) {
        uint256 y0 = getY(x, K, o, t);
        assembly {
            k := sub(y, y0)
        }
    }

    function getX(
        uint256 y,
        uint256 K,
        uint256 o,
        uint256 t
    ) internal view returns (uint256 x) {
        int256 sec; //= diviWad(t, YEAR);
        assembly {
            sec := div(mul(t, ONE), YEAR)
        }
        int256 vol = sec.sqrt(); // = int256(FixedPointMathLib.sqrt(uint256(sec)));
        //vol = muliWad(o, vol);

        int256 phi;
        assembly {
            vol := mul(vol, HALF_SCALAR)
            vol := div(mul(o, vol), ONE)
            phi := sdiv(mul(y, ONE), K)
        }
        phi = phi.ppf();

        //int256 phi = diviWad(y, K).ppf();
        //int256 input = phi + vol;
        int256 input;
        assembly {
            input := add(phi, vol)
        }
        input = input.cdf();
        //x = ONE - input.cdf();
        assembly {
            x := sub(ONE, input)
        }
    }
}
