// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Invariant} from "../../contracts/Invariant.sol";
import {TestInvariant} from "../../contracts/test/TestInvariant.sol";

contract TInvariant is Test {
    function _base(uint256 asset) internal pure returns (uint256) {
        return uint256(asset % uint256(Invariant.ONE)); // Between 0 and 1e18. Todo: fix for token decimals.
    }

    function _quote(uint256 quote, uint256 strike)
        internal
        pure
        returns (uint256)
    {
        return uint256(quote % strike); // Between 0 and strike.
    }

    function _strike(uint256 strike) internal pure returns (uint256) {
        return uint256(1 + (strike % (type(uint128).max - 1))); // Between 1 and 2^32 - 1.
    }

    function _sigma(uint256 sigma) internal pure returns (uint256) {
        return uint256(1 + (sigma % (type(uint24).max - 1))); // Between 1 and (2^24 - 1).
    }

    function _tau(uint256 tau, uint256 time) internal pure returns (uint256) {
        return
            uint256(
                (time + (tau % (type(uint32).max - 1))) *
                    uint256(Invariant.YEAR)
            ); // Between block.timestamp and 2^32 - 1.
    }

    function getArgs() internal pure returns (TestInvariant.Args memory) {
        TestInvariant.Args memory args = TestInvariant.Args(
            308537538726e6,
            1e18,
            1e18,
            1e18
        );
        return args;
    }

    function testGetYGas() public logs_gas {
        uint256 actual = TestInvariant.getY(getArgs());
    }

    function testGetXGas() public logs_gas {
        uint256 actual = TestInvariant.getX(getArgs());
    }

    function testInvariantGas() public logs_gas {
        uint256 y = 308537538726e6;
        int256 actual = TestInvariant.invariant(getArgs(), y);
    }

    function testFuzzInvariant(
        uint256 quote,
        uint256 asset,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public {
        TestInvariant.Args memory args = TestInvariant.Args(
            _base(asset),
            _strike(strike),
            _sigma(sigma),
            _tau(tau, block.timestamp)
        );

        console.log(args.x);
        console.log(args.K);
        console.log(args.o);
        console.log(args.t);
        int256 k = TestInvariant.invariant(args, _quote(quote, args.K));
        if (args.t == 0) {
            int256 expected = int256(
                (args.K * (uint256(Invariant.ONE) - args.x)) / 1e18
            );
            assertEq(k, expected);
        }
        emit log_int(k);
    }
}
