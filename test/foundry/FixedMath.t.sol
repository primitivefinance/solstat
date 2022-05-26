// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/FixedMath.sol";

contract TestRaw is Test {
    function testAbs() public logs_gas {
        FixedMath.rawAbs(1);
        FixedMath.rawAbs(-1);
    }
}

Fixed256x18 constant v = Fixed256x18.wrap(-1);

contract TestSMath is Test {
    function testMax() public {
        int256 maxInt = type(int256).max;
        console.logInt(maxInt);
    }

    function abs(int256 x) public returns (UFixed18) {
        return FixedMath.abs(Fixed256x18.wrap(x));
    }

    function absUnchecked(int256 x) public returns (UFixed18) {
        return FixedMath.absUnchecked(Fixed256x18.wrap(x));
    }

    function rawAbs(int256 x) public returns (uint256) {
        return FixedMath.rawAbs(x);
    }

    function testRaw() public logs_gas {
        //FixedMath.rawAbs(1);
        FixedMath.rawAbs(-1);
    }

    function testAbs() public logs_gas {
        //FixedMath.abs(Fixed256x18.wrap(1));
        //FixedMath.abs(Fixed256x18.wrap(-1));
        FixedMath.abs(v);
    }

    function testAbs02() public {
        FixedMath.absUnchecked(Fixed256x18.wrap(1));
        FixedMath.absUnchecked(Fixed256x18.wrap(-1));
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
        Fixed256x18 value = Fixed256x18.wrap(initial);
        int256 actual = FixedNumber.assembly_unwrap(value);
        int256 expected = Fixed256x18.unwrap(value);
        assertEq(actual, expected);
        assertEq(actual, initial);
    }
}
