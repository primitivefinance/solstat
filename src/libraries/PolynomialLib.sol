// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "./RayMathLib.sol";

////////////////
//  Errors    //
////////////////

error InvalidLength();

////////////////
// Functions  //
////////////////

/// @dev Evaluates a polynomial of the form:
///      y = coef[0] + coef[1]*x + coef[2]*x^2 + ... + coef[N]*x^N
///      The function is evaluated by Horner's method.
/// @custom:reference Inspired by https://github.com/jeremybarnes/cephes/blob/master/cprob/polevl.c
/// @param x The value at which the polynomial is evaluated.
/// @param coef The coefficients of the polynomial.
/// @param N The degree of the polynomial.
/// @return y The value of the polynomial at x.
function polevl(int256 x, int256[] memory coef, uint256 N) pure returns (int256 y) {
    if (N >= coef.length) revert InvalidLength();

    y = coef[0];
    for (uint256 i = 1; i <= N; i++) {
        y = mulfp(y, x) + coef[i];
    }

    return y;
}

/// @dev Evaluate polynomial when coefficient of x is 1.0. Otherwise same as polevl.
/// @custom:reference Inspired by https://github.com/jeremybarnes/cephes/blob/master/cprob/polevl.c
/// @param x The value at which the polynomial is evaluated.
/// @param coef The coefficients of the polynomial.
/// @param N The degree of the polynomial.
/// @return y The value of the polynomial at x.
function p1evl(int256 x, int256[] memory coef, uint256 N) pure returns (int256 y) {
    if (N > coef.length) revert InvalidLength();

    y = x + coef[0];
    for (uint256 i = 1; i < N; i++) {
        y = mulfp(y, x) + coef[i];
    }
    return y;
}
