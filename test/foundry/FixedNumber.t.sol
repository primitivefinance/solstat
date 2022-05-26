// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/FixedNumber.sol";

contract TestFixedNumber is Test {
    using FixedNumber for Fixed256x18;
    using FixedNumber for int256;

    int256 public constant negative = -4;
    int256 public constant one = 1;
    Fixed256x18 public constant v = Fixed256x18.wrap(-4);

    function testAddGas() public logs_gas {
        v.add(one);
    }

    function testAddFuzz(int256 input, int256 adder) public {
        vm.assume(input != 0);
        vm.assume(adder != 0);
        int256 a = Fixed256x18.unwrap(
            Fixed256x18.wrap(input).add(Fixed256x18.wrap(adder))
        );
        int256 b = Fixed256x18.unwrap(Fixed256x18.wrap(input).add(adder));
        int256 c = Fixed256x18.unwrap(input.add(Fixed256x18.wrap(adder)));
        int256 d = Fixed256x18.unwrap(input.add(adder));
        assertEq(a, b);
        assertEq(b, c);
    }

    function testLt() public {
        int256 initial = -15;
        Fixed256x18 value = Fixed256x18.wrap(initial);
        bool actual = value.lt(0);
        bool expected = initial < 0;
        assertEq(actual, expected);
    }
}
