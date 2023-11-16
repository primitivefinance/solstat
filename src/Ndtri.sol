// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/utils/FixedPointMathLib.sol";

import "./libraries/RayMathLib.sol";
import "./libraries/PolynomialLib.sol";
import "./libraries/ArrayLib.sol";

import {console2 as logger} from "forge-std/console2.sol"; // todo: remove

/// @dev This library implements the Inverse normal cumulative distribution function (PPF).
///      Also known as the percent point function or quantile function.
///      The implementation is inspired by the algorithm implemented in the Cephes library.
/// @custom:reference https://github.com/jeremybarnes/cephes/blob/master/cprob/ndtri.c
library Ndtri {
    ////////////////
    // Errors     //
    ////////////////

    error MaxNumError();

    ////////////////
    // Constants  //
    ////////////////

    int256 constant RAY_EXPNEG2 = 0.135335283236612691893999494e27;

    //////////////////////////////////////////////
    // Approximation for 0 <= |y - 0.5| <= 3/8  //
    //////////////////////////////////////////////

    int256 constant P0_LENGTH = 5;
    bytes constant P0 = abi.encodePacked(
        [
            -int256(5.99633501014107895267e28),
            int256(9.80010754185999661536e28),
            -int256(5.66762857469070293439e28),
            int256(1.39312609387279679503e28),
            -int256(1.23916583867381258016e27)
        ]
    );

    int256 constant Q0_LENGTH = 8;
    bytes constant Q0 = abi.encodePacked(
        [
            int256(1.95448858338141759834e27),
            int256(4.67627912898881538453e27),
            int256(8.63602421390890590575e28),
            -int256(2.25462687854119370527e29),
            int256(2.00260212380060660359e29),
            -int256(8.20372256168333339912e28),
            int256(1.59056225126211695515e28),
            -int256(1.18331621121330003142e27)
        ]
    );

    /////////////////////////////////////////////////////////////////////
    // Approximation for interval z = sqrt(-2 log y ) between 2 and 8  //
    // i.e., y between exp(-2) = .135 and exp(-32) = 1.27e-14.         //
    /////////////////////////////////////////////////////////////////////

    uint256 constant P1_LENGTH = 9;
    bytes constant P1 = abi.encodePacked(
        [
            int256(4.05544892305962419923e27),
            int256(3.15251094599893866154e28),
            int256(5.71628192246421288162e28),
            int256(4.408050738932008347e28),
            int256(1.46849561928858024014e28),
            int256(2.18663306850790267539e27),
            -int256(1.40256079171354495875e26),
            -int256(3.50424626827848203418e25),
            -int256(8.57456785154685413611e23)
        ]
    );

    uint256 constant Q1_LENGTH = 8;
    bytes constant Q1 = abi.encodePacked(
        [
            int256(1.57799883256466749731e28),
            int256(4.53907635128879210584e28),
            int256(4.1317203825467203044e28),
            int256(1.50425385692907503408e28),
            int256(2.50464946208309415979e27),
            -int256(1.42182922854787788574e26),
            -int256(3.80806407691578277194e25),
            -int256(9.33259480895457427372e23)
        ]
    );

    //////////////////////////////////////////////////////////////////////
    // Approximation for interval z = sqrt(-2 log y ) between 8 and 64  //
    // i.e., y between exp(-32) = 1.27e-14 and exp(-2048) = 3.67e-890.  //
    //////////////////////////////////////////////////////////////////////

    uint256 constant P2_LENGTH = 9;
    bytes constant P2 = abi.encodePacked(
        [
            int256(3.2377489177694603597e27),
            int256(6.91522889068984211695e27),
            int256(3.93881025292474443415e27),
            int256(1.33303460815807542389e27),
            int256(2.01485389549179081538e26),
            int256(1.23716634817820021358e25),
            int256(3.01581553508235416007e23),
            int256(2.65806974686737550832e21),
            int256(6.239745391849832937e18) // todo: missing a 3 at the end! bad?
        ]
    );

    uint256 constant Q2_LENGTH = 8;
    bytes constant Q2 = abi.encodePacked(
        [
            int256(6.02427039364742014255e27),
            int256(3.67983563856160859403e27),
            int256(1.37702099489081330271e27),
            int256(2.1623699359449663589e26),
            int256(1.34204006088543189037e25),
            int256(3.28014464682127739104e23),
            int256(2.89247864745380683936e21),
            int256(6.790194080099812744e18) // missing a 25 at the end! todo: fix?
        ]
    );

    ////////////////
    // Functions  //
    ////////////////

    /// todo: need sqrt function with enough precision
    /// along with log
    /// todo: precision. Looks like it loses precision towards the bounds. Maybe better sqrt resolves.
    function ndtri(int256 y0) internal view returns (int256) {
        int256 x;
        int256 y;
        int256 z;
        int256 y2;
        int256 x0;
        int256 x1;

        if (y0 <= 0) revert MaxNumError();
        if (y0 >= RAY_ONE) revert MaxNumError();

        int256 code = 1;

        y = y0;

        // Use a different approximation if y > exp(-2).
        if (y > RAY_ONE - RAY_EXPNEG2) {
            // 0.135... = exp(-2)
            y = RAY_ONE - y;
            code = 0;
        }

        if (y > RAY_EXPNEG2) {
            int256[] memory P0_ARRAY = copy5(abi.decode(P0, (int256[5])));
            int256[] memory Q0_ARRAY = copy8(abi.decode(Q0, (int256[8])));
            y = y - RAY_HALF;
            y2 = mulfp(y, y);
            x = y + mulfp(y, (y2 * polevl(y2, P0_ARRAY, 4) / p1evl(y2, Q0_ARRAY, 8)));
            x = mulfp(x, RAY_SQRT2PI);
            return x;
        }

        // `y` is assumed to be a probability between 0 and 1.
        // This transformation is part of the formula for the quantile function of the normal distribution
        // and serves to adjust the scale and distribution of the data.
        // It also helps ensure that x will be a positive number because we're taking the square root.
        // The -2.0 * log(y) essentially gives the quantile of the exponential distribution,
        // which is then square rooted to approximate the quantile for the normal distribution.

        // The precision of the sqrt output affects every value after this point.
        // i.e. x0 will have precision up to the sqrt precision, and so on.
        x = sqrtfp(mulfp(-RAY_TWO, logfp(y))); // √(-2 * ln(y))

        // Part of a numerical approximation method (like a variant of Newton's method)
        // to refine the value of x to make it a better approximation.
        x0 = x - divfp(logfp(x), x); // x - ln(x) / x

        z = divfp(RAY_ONE, x);
        if (x < RAY_EIGHT) {
            int256[] memory P1_ARRAY = copy9(abi.decode(P1, (int256[9])));
            int256[] memory Q1_ARRAY = copy8(abi.decode(Q1, (int256[8])));
            x1 = z * polevl(z, P1_ARRAY, uint256(8)) / p1evl(z, Q1_ARRAY, uint256(8));
        } else {
            int256[] memory P2_ARRAY = copy9(abi.decode(P2, (int256[9])));
            int256[] memory Q2_ARRAY = copy8(abi.decode(Q2, (int256[8])));
            x1 = z * polevl(z, P2_ARRAY, uint256(8)) / p1evl(z, Q2_ARRAY, uint256(8));
        }

        x = x0 - x1;
        if (code != 0) {
            x = -x;
        }

        return x;
    }
}
