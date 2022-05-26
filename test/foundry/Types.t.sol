// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/Types.sol";

contract TestTypes is Test {
    using Types for Fixed18;
    using Types for int256;

    function testWrapGas() public logs_gas {
        Fixed18.wrap(-4);
    }

    int256 public constant negative = -4;
    int256 public constant one = 1;
    Fixed18 public constant v = Fixed18.wrap(-4);

    function testUnwrapGas() public logs_gas {
        Fixed18.unwrap(v);
    }

    function testWrapUnwrapGas() public logs_gas {
        Fixed18.unwrap(v);
    }

    function testAddGas() public logs_gas {
        v.add(one);
    }

    function testAddRawGas() public logs_gas {
        negative.addRaw(one);
    }

    function testAddUncheckedGas() public logs_gas {
        v.addUnchecked(one);
    }

    function test00() public returns (bool) {
        return v.lt(0);
    }

    function test01() public returns (bool) {
        int256 x = -4;
        return x < 0;
    }

    function testGasGte() public logs_gas returns (bool) {
        v.gte(4);
    }

    function testAddFuzz(int256 input, int256 adder) public {
        vm.assume(input != 0);
        vm.assume(adder != 0);
        int256 a = Fixed18.unwrap(Fixed18.wrap(input).add(Fixed18.wrap(adder)));
        int256 b = Fixed18.unwrap(Fixed18.wrap(input).add(adder));
        int256 c = Fixed18.unwrap(input.add(Fixed18.wrap(adder)));
        int256 d = Fixed18.unwrap(input.add(adder));
        assertEq(a, b);
        assertEq(b, c);
    }

    function testLt() public {
        int256 initial = -15;
        Fixed18 value = Fixed18.wrap(initial);
        bool actual = value.lt(0);
        bool expected = initial < 0;
        assertEq(actual, expected);
    }
}
