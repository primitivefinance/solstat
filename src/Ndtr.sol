// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/utils/FixedPointMathLib.sol";

import "./libraries/RayMathLib.sol";
import "./libraries/PolynomialLib.sol";
import "./libraries/ArrayLib.sol";

import {console2 as logger} from "forge-std/console2.sol"; // todo: remove

/// @dev This library implements the Normal cumulative distribution function (CDF).
///      The implementation is inspired by the algorithm implemented in the Cephes library.
/// @custom:reference https://github.com/jeremybarnes/cephes/blob/master/cprob/ndtr.c
library Ndtr {
    ////////////////
    // Constants  //
    ////////////////

    /// @dev
    /// In the context of the erf and erfc functions,
    /// the square root of 0.5 is used as a boundary value for a range check.
    /// When the absolute value of the input x is smaller than the square root of 0.5,
    /// a series expansion is used to compute the function's value.
    /// Otherwise, a continued fraction expansion is used.
    ///
    /// These two different methods for computing the error function and
    /// the complementary error function provide a balance between
    /// accuracy and computational efficiency,
    /// depending on the size of the input.
    int256 constant RAY_SQRTH = 0.7071067811865475244e27; // sqrt(5) = 0.7071067811865475244

    uint256 constant P_LENGTH = 9;
    bytes constant P = abi.encodePacked(
        [
            int256(2.46196981473530512e17), // P[0] is missing 524, decimal places 28-30. todo: check out?
            int256(5.64189564831068821977e26),
            int256(7.46321056442269912687e27),
            int256(4.86371970985681366614e28),
            int256(1.96520832956077098242e29),
            int256(5.26445194995477358631e29),
            int256(9.3452852717195760754e29),
            int256(1.02755188689515710272e30),
            int256(5.57535335369399327526e29)
        ]
    );

    uint256 constant Q_LENGTH = 8;
    bytes constant Q = abi.encodePacked(
        [
            // 1.0e27
            1.32281951154744992508e28,
            8.67072140885989742329e28,
            3.54937778887819891062e29,
            9.75708501743205489753e29,
            1.82390916687909736289e30,
            2.24633760818710981792e30,
            1.65666309194161350182e30,
            5.57535340817727675546e29
        ]
    );

    uint256 constant R_LENGTH = 6;
    bytes constant R = abi.encodePacked(
        [
            5.64189583547755073984e26,
            1.27536670759978104416e27,
            5.01905042251180477414e27,
            6.16021097993053585195e27,
            7.4097426995044893916e27,
            2.9788666537210024067e27
        ]
    );

    uint256 constant S_LENGTH = 6;
    bytes constant S = abi.encodePacked(
        [
            // 1.0e27
            2.2605286322011727659e27,
            9.39603524938001434673e27,
            1.20489539808096656605e28,
            1.70814450747565897222e28,
            9.60896809063285878198e27,
            3.3690764510008151605e27
        ]
    );

    uint256 constant T_LENGTH = 5;
    bytes constant T = abi.encodePacked(
        [
            9.60497373987051638749e27,
            9.00260197203842689217e28,
            2.23200534594684319226e30,
            7.00332514112805075473e30,
            5.55923013010394962768e31
        ]
    );

    uint256 constant U_LENGTH = 5;
    bytes constant U = abi.encodePacked(
        [
            // 1.0e27
            3.35617141647503099647e28,
            5.21357949780152679795e29,
            4.59432382970980127987e30,
            2.26290000613890934246e31,
            4.92673942608635921086e31
        ]
    );

    ////////////////
    // Functions  //
    ////////////////

    /// todo: need to handling rounding, unless we want to default to truncation.
    function ndtr(int256 a) internal view returns (int256) {
        int256 x;
        int256 y;
        int256 z;

        x = mulfp(a, RAY_SQRTH); // x = a * RAY_SQRTH;
        z = absolute(x);

        if (z < RAY_ONE) {
            y = RAY_HALF + mulfp(RAY_HALF, erf(x)); // y = RAY_HALF + RAY_HALF * erf(x);
        } else {
            y = mulfp(RAY_HALF, erfc(z)); // y = RAY_HALF * erfc(z);

            if (x > 0) y = RAY_ONE - y;
        }

        return y;
    }

    function erfc(int256 a) internal view returns (int256) {
        int256 p;
        int256 q;
        int256 x;
        int256 y;
        int256 z;

        if (a < 0) x = -a;
        else x = a;

        if (x < RAY_ONE) return RAY_ONE - erf(a);

        z = -mulfp(a, a); // z = -a * a;

        if (z < -RAY_MAXLOG) {
            if (a < 0) return RAY_TWO;
            else return 0;
        }

        z = expfp(z);

        if (x < RAY_EIGHT) {
            int256[] memory input0 = copy9(abi.decode(P, (int256[9])));
            p = polevl(x, input0, 8); // p = P[0] + P[1]*x + ... + P[8]*x^8
            int256[] memory input1 = copy8(abi.decode(Q, (int256[8])));
            q = p1evl(x, input1, 8); // q = 1 + Q[0]*x + ... + Q[7]*x^7
        } else {
            int256[] memory input0 = copy6(abi.decode(R, (int256[6])));
            p = polevl(x, input0, 5); // p = R[0] + R[1]*x + ... + R[5]*x^5
            int256[] memory input1 = copy6(abi.decode(S, (int256[6])));
            q = p1evl(x, input1, 6); // q = 1 + S[0]*x + ... + S[6]*x^6
        }

        y = (z * p) / q;

        if (a < 0) y = RAY_TWO - y;

        if (y == 0) {
            if (a < 0) y = RAY_TWO;
            else y = 0;
        }

        return y;
    }

    /// @dev Exponentially scaled erfc function.
    ///      exp(x^2) erfc(x)
    ///      valid for x > 1
    function erfce(int256 x) internal view returns (int256) {
        int256 p;
        int256 q;

        if (x < RAY_EIGHT) {
            int256[] memory input0 = copy9(abi.decode(P, (int256[9])));
            p = polevl(x, input0, 8); // p = P[0] + P[1]*x + ... + P[8]*x^8
            int256[] memory input1 = copy8(abi.decode(Q, (int256[8])));
            q = p1evl(x, input1, 8); // q = 1 + Q[0]*x + ... + Q[7]*x^7
        } else {
            int256[] memory input0 = copy6(abi.decode(R, (int256[6])));
            p = polevl(x, input0, 5); // p = R[0] + R[1]*x + ... + R[5]*x^5
            int256[] memory input1 = copy6(abi.decode(S, (int256[6])));
            q = p1evl(x, input1, 6); // q = 1 + S[0]*x + ... + S[6]*x^6
        }

        return divfp(p, q); // p / q;
    }

    function erf(int256 x) internal view returns (int256) {
        int256 y;
        int256 z;

        if (absolute(x) > RAY_ONE) return RAY_ONE - erfc(x);

        z = mulfp(x, x); // z = x * x;

        int256[] memory input0 = copy5(abi.decode(T, (int256[5])));
        int256[] memory input1 = copy5(abi.decode(U, (int256[5])));
        // p = T[0] + T[1]*z + ... + T[4]*z^4
        // q = 1 + U[0]*z + ... + U[4]*z^5
        // y = z * p / q
        y = x * polevl(z, input0, 4) / p1evl(z, input1, 5);

        return y;
    }
}
