// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Invariant} from "../../contracts/Invariant.sol";

contract TestInvariant is Test {
    function getArgs() internal pure returns (Invariant.Args memory) {
        Invariant.Args memory args = Invariant.Args(
            308537538726e6,
            1e18,
            1e18,
            1e18
        );
        return args;
    }

    function testGetYGas() public logs_gas {
        int256 actual = Invariant.getY(getArgs());
    }

    function testGetXGas() public logs_gas {
        int256 actual = Invariant.getX(getArgs());
    }

    function testInvariantGas() public logs_gas {
        int256 y = 308537538726e6;
        int256 actual = Invariant.invariant(getArgs(), y);
    }
}
