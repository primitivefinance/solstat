// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/utils/FixedPointMathLib.sol";

////////////////
// Constants  //
////////////////

int256 constant RAY = 1e27;
int256 constant RAY_HALF = 0.5e27;
int256 constant RAY_ONE = RAY;
int256 constant RAY_TWO = 2e27;
int256 constant RAY_EIGHT = 8e27;
int256 constant RAY_SQRT2 = 1.41421356237309504880168872e27; // sqrt(2)
int256 constant RAY_SQRT2PI = 2.50662827463100050242e27; // sqrt(2pi)
int256 constant RAY_MAXLOG = 7.09782712893383996843e29; // ln(2^255)

////////////////
// Arithmetic //
////////////////

/// @dev Fixed point multiplication, truncates.
function mulfp(int256 a, int256 b) pure returns (int256) {
    return (a * b) / RAY;
}

/// @dev Fixed point multiplication, truncates.
function mulfp(uint256 a, uint256 b) pure returns (uint256) {
    return (a * b) / uint256(RAY);
}

/// @dev Fixed point division, truncates.
function divfp(int256 a, int256 b) pure returns (int256) {
    return a * RAY / b;
}

/// @dev Fixed point division, truncates.
function divfp(uint256 a, uint256 b) pure returns (uint256) {
    return a * uint256(RAY) / b;
}

////////////////
// Functions  //
////////////////

/// @dev Returns the absolute value of a number.
/// todo: do we need type checking?
function absolute(int256 x) pure returns (int256) {
    if (x < 0) return -x;
    else return x;
}

/// @dev Up to 1E18 precision.
/// todo: need more precise sqrt for 1e27 precision.
function sqrtfp(int256 x) pure returns (int256) {
    x = x / 1e9; // Scale from 1e27 -> 1e18.

    uint256 result = FixedPointMathLib.sqrt(uint256(x));
    if (result > uint256(type(int256).max)) revert("sqrt-overflow");

    return int256(result) * 1e18; // Multiplies by 1e18 since the sqrt of 1e18 units is 9, so multiply by 1e18 to get 1e27 units.
}

/// @dev todo
function logfp(int256 x) pure returns (int256) {
    x = x / 1e9 + 1;
    return int256(FixedPointMathLib.lnWad(x)) * 1e9; // todo: fix, this is temp
}

/// @dev todo
function expfp(int256 x) pure returns (int256) {
    x = x / 1e9;

    int256 result = FixedPointMathLib.expWad(x);

    return result * 1e9; // todo: fix, this is temp, scale from 1E18 -> 1E27
}