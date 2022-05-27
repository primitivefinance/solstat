// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title Invariant of Primitive RMM.
 * @dev `y - KΦ(Φ⁻¹(1-x) - σ√τ) = k`
 */
library Invariant {
    uint256 internal constant YEAR = 31556952;
}
