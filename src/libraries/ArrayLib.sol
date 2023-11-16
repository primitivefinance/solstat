// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

////////////////
// Functions  //
////////////////

/// @dev Copies a fixed-size array of 5 elements into a new dynamically allocated array.
function copy5(int256[5] memory input) pure returns (int256[] memory) {
    uint256 len = input.length;
    int256[] memory output = new int256[](len);
    for (uint256 i; i < len; i++) {
        output[i] = input[i];
    }
    return output;
}

/// @dev Copies a fixed-size array of 6 elements into a new dynamically allocated array.
function copy6(int256[6] memory input) pure returns (int256[] memory) {
    uint256 len = input.length;
    int256[] memory output = new int256[](len);
    for (uint256 i; i < len; i++) {
        output[i] = input[i];
    }
    return output;
}

/// @dev Copies a fixed-size array of 7 elements into a new dynamically allocated array.
function copy7(int256[7] memory input) pure returns (int256[] memory) {
    uint256 len = input.length;
    int256[] memory output = new int256[](len);
    for (uint256 i; i < len; i++) {
        output[i] = input[i];
    }
    return output;
}

/// @dev Copies a fixed-size array of 8 elements into a new dynamically allocated array.
function copy8(int256[8] memory input) pure returns (int256[] memory) {
    uint256 len = input.length;
    int256[] memory output = new int256[](len);
    for (uint256 i; i < len; i++) {
        output[i] = input[i];
    }
    return output;
}

/// @dev Copies a fixed-size array of 9 elements into a new dynamically allocated array.
function copy9(int256[9] memory input) pure returns (int256[] memory) {
    uint256 len = input.length;
    int256[] memory output = new int256[](len);
    for (uint256 i; i < len; i++) {
        output[i] = input[i];
    }
    return output;
}
