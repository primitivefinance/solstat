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
function absolute(int256 x) view returns (int256) {
    if (x < 0) return -x;
    else return x;
}

/// @dev Up to 1E18 precision.
function sqrtfp(int256 x) view returns (int256) {
    uint256 result = sqrt(uint256(x));
    if (result > uint256(type(int256).max)) revert("overflow");

    return int256(result) * 1e14; // Multiplies by 1e14 since the sqrt of 1e27 units is 1e13.5.
}

/// @dev todo
function logfp(int256 x) view returns (int256) {
    x = x / 1e9 + 1;
    return int256(FixedPointMathLib.lnWad(x)) * 1e9; // todo: fix, this is temp
}

/// @notice Calculates the square root of x using the Babylonian method.
///
/// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Notes:
/// - If x is not a perfect square, the result is rounded down.
/// - Credits to OpenZeppelin for the explanations in comments below.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$, and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus, we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // If x is not a perfect square, round the result toward zero.
        uint256 roundedResult = x / result;
        if (result >= roundedResult) {
            result = roundedResult;
        }
    }
}
