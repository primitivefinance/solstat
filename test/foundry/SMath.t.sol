// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/SMath.sol";

contract TestRaw is Test {
    function testAbs() public logs_gas {
        SMath.rawAbs(1);
        SMath.rawAbs(-1);
    }
}

Fixed18 constant v = Fixed18.wrap(-1);

contract TestSMath is Test {
    function abs(int256 x) public returns (UFixed18) {
        return SMath.abs(Fixed18.wrap(x));
    }

    function absUnchecked(int256 x) public returns (UFixed18) {
        return SMath.absUnchecked(Fixed18.wrap(x));
    }

    function rawAbs(int256 x) public returns (uint256) {
        return SMath.rawAbs(x);
    }

    function testRaw() public logs_gas {
        //SMath.rawAbs(1);
        SMath.rawAbs(-1);
    }

    function testAbs() public logs_gas {
        //SMath.abs(Fixed18.wrap(1));
        //SMath.abs(Fixed18.wrap(-1));
        SMath.abs(v);
    }

    function testAbs02() public {
        SMath.absUnchecked(Fixed18.wrap(1));
        SMath.absUnchecked(Fixed18.wrap(-1));
    }

    function testAbsFuzz(int256 z) public {
        vm.assume(z != type(int256).min);
        console.logInt(z);
        uint256 actual = UFixed18.unwrap(abs(z));
        uint256 y = UFixed18.unwrap(absUnchecked(z));
        uint256 raw = rawAbs(z);
        uint256 expected;
        unchecked {
            expected = uint256(z < 0 ? -z : z);
        }
        console.log(actual);
        console.log(expected);
        assertEq(actual, expected);
        assertEq(y, actual);
        assertEq(raw, y);
    }

    function testUnwrap() public {
        int256 initial = -15;
        Fixed18 value = Fixed18.wrap(initial);
        int256 actual = Types.assembly_unwrap(value);
        int256 expected = Fixed18.unwrap(value);
        assertEq(actual, expected);
        assertEq(actual, initial);
    }
}
