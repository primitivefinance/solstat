// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/FixedMath.sol";

Fixed256x18 constant v = Fixed256x18.wrap(-1);

contract TestFixedMath is Test {
    using FixedMath for Fixed256x18;

    function testAbsGas() public logs_gas {
        v.abs();
    }

    function testAbsFuzz(int256 z) public {
        vm.assume(z != type(int256).min);
        uint256 actual = UFixed256x18.unwrap(Fixed256x18.wrap(z).abs());
        uint256 expected;
        unchecked {
            expected = uint256(z < 0 ? -z : z);
        }
        assertEq(actual, expected);
    }

    function testAbsRevertMin() public {
        vm.expectRevert(FixedMath.Min.selector);
        int256 z = type(int256).min;
        Fixed256x18.wrap(z).abs();
    }

    function testExpGas() public logs_gas {}

    function testExpFuzz(int256 z) public {}

    function testExpRevertMax() public {}
}
