// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Gaussian as GaussianBetter, FixedPointMathLib} from "./Gaussian.sol";
import {Gaussian} from "./reference/AssemblyGaussian.sol";

library CFRMM {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;
    uint256 internal constant PERCENTAGE = 10_000;
    uint256 internal constant SQRT_WAD = 1e9;
    uint256 internal constant WAD = 1 ether;
    uint256 internal constant YEAR = 31556953 seconds;

    error OverflowWad(int256);
    error UndefinedPrice();

    /// @custom:math R_x = 1 - Φ(( ln(S/K) + (σ²/2)τ ) / σ√τ)
    function getXWithPrice(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 R_x) {
        if (prc != 0) {
            int256 ln = FixedPointMathLib.lnWad(
                int256(FixedPointMathLib.divWadDown(prc, stk))
            );
            uint256 tauYears = convertSecondsToWadYears(tau);

            uint256 sigmaWad = convertPercentageToWad(vol);
            uint256 doubleSigma = (sigmaWad * sigmaWad) /
                uint256(GaussianBetter.TWO);
            uint256 halfSigmaTau = doubleSigma * tauYears;
            uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(
                sigmaWad
            );

            int256 lnOverVol = (ln *
                GaussianBetter.ONE +
                int256(halfSigmaTau)) / int256(sqrtTauSigma);
            int256 cdf = GaussianBetter.cdf(lnOverVol);
            if (cdf > GaussianBetter.ONE) revert OverflowWad(cdf);
            R_x = uint256(GaussianBetter.ONE - cdf);
        }
    }

    function getPriceWithX(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 prc) {
        uint256 tauYears = convertSecondsToWadYears(tau);
        uint256 volWad = convertPercentageToWad(vol);

        if (uint256(GaussianBetter.ONE) < R_x) revert OverflowWad(int256(R_x));
        if (R_x == 0) revert UndefinedPrice(); // As lim_x->0, S(x) = +infinity.
        if (tauYears == 0 || volWad == 0) return stk; // Ke^(0 - 0) = K.
        if (R_x == uint256(GaussianBetter.ONE)) return stk; // As lim_x->1, S(x) = 0 for all tau > 0 and vol > 0.

        int256 input = GaussianBetter.ONE - int256(R_x);
        int256 ppf = GaussianBetter.ppf(input);
        uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(volWad);
        int256 first = (ppf * int256(sqrtTauSigma)) / GaussianBetter.ONE; // Φ^-1(1 - R_x)σ√τ
        uint256 doubleSigma = (volWad * volWad) / uint256(GaussianBetter.TWO);
        int256 halfSigmaTau = int256(doubleSigma * tauYears) /
            GaussianBetter.ONE; // 1/2σ^2τ

        int256 exponent = first - halfSigmaTau;
        int256 exp = exponent.expWad();
        prc = uint256(exp).mulWadDown(stk);
    }

    function getPriceWithXReference(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 prc) {
        uint256 tauYears = convertSecondsToWadYears(tau);
        uint256 volWad = convertPercentageToWad(vol);

        if (uint256(Gaussian.ONE) < R_x) revert OverflowWad(int256(R_x));
        if (R_x == 0) revert UndefinedPrice(); // As lim_x->0, S(x) = +infinity.
        if (tauYears == 0 || volWad == 0) return stk; // Ke^(0 - 0) = K.
        if (R_x == uint256(Gaussian.ONE)) return stk; // As lim_x->1, S(x) = 0 for all tau > 0 and vol > 0.

        int256 input = Gaussian.ONE - int256(R_x);
        int256 ppf = Gaussian.ppf(input);
        uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(volWad);
        int256 first = (ppf * int256(sqrtTauSigma)) / Gaussian.ONE; // Φ^-1(1 - R_x)σ√τ
        uint256 doubleSigma = (volWad * volWad) / uint256(Gaussian.TWO);
        int256 halfSigmaTau = int256(doubleSigma * tauYears) / Gaussian.ONE; // 1/2σ^2τ

        int256 exponent = first - halfSigmaTau;
        int256 exp = exponent.expWad();
        prc = uint256(exp).mulWadDown(stk);
    }

    function convertSecondsToWadYears(uint256 sec)
        internal
        pure
        returns (uint256 yrsWad)
    {
        assembly {
            yrsWad := div(mul(sec, WAD), YEAR)
        }
    }

    function convertPercentageToWad(uint256 pct)
        internal
        pure
        returns (uint256 pctWad)
    {
        assembly {
            pctWad := div(mul(pct, WAD), PERCENTAGE)
        }
    }

    function getXWithPriceReference(
        uint256 prc,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) internal pure returns (uint256 R_x) {
        if (prc != 0) {
            int256 ln = FixedPointMathLib.lnWad(
                int256(FixedPointMathLib.divWadDown(prc, stk))
            );
            uint256 tauYears = convertSecondsToWadYears(tau);

            uint256 sigmaWad = convertPercentageToWad(vol);
            uint256 doubleSigma = (sigmaWad * sigmaWad) / uint256(Gaussian.TWO);
            uint256 halfSigmaTau = doubleSigma * tauYears;
            uint256 sqrtTauSigma = (tauYears.sqrt() * SQRT_WAD).mulWadDown(
                sigmaWad
            );

            int256 lnOverVol = (ln * Gaussian.ONE + int256(halfSigmaTau)) /
                int256(sqrtTauSigma);
            int256 cdf = Gaussian.cdf(lnOverVol);
            if (cdf > Gaussian.ONE) revert OverflowWad(cdf);
            R_x = uint256(Gaussian.ONE - cdf);
        }
    }
}
