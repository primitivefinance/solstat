// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Invariant} from "src/Invariant.sol";
import {HelperInvariant} from "src/test/HelperInvariant.sol";

contract TInvariant is Test {
    function _base(uint256 asset) internal view returns (uint256) {
        return bound(asset, 0, uint256(Invariant.ONE)); // Between 0 and 1e18. Todo: fix for token decimals.
    }

    function _quote(uint256 quote, uint256 strike)
        internal
        view
        returns (uint256)
    {
        return bound(quote, 0, strike); // Between 0 and strike.
    }

    function _strike(uint256 strike) internal view returns (uint256) {
        return bound(strike, 1, type(uint128).max - 1); // Between 1 and 2^128 - 1.
    }

    function _sigma(uint256 sigma) internal view returns (uint256) {
        return bound(sigma, 1, type(uint24).max - 1); // Between 1 and (2^24 - 1).
    }

    function _tau(uint256 tau, uint256 time) internal view returns (uint256) {
        return
            bound(tau, time, (type(uint32).max - 1) * uint256(Invariant.YEAR)); // Between block.timestamp and 2^32 - 1, in units of years.
    }

    function getArgs() internal pure returns (HelperInvariant.Args memory) {
        HelperInvariant.Args memory args = HelperInvariant.Args(
            308537538726e6,
            1e18,
            1e18,
            1e18
        );
        return args;
    }

    function testGetYGas() public logs_gas {
        uint256 actual = HelperInvariant.getY(getArgs());
        actual;
    }

    function testGetXGas() public logs_gas {
        uint256 actual = HelperInvariant.getX(getArgs());
        actual;
    }

    function HelperInvariantGas() public logs_gas {
        uint256 y = 308537538726e6;
        int256 actual = HelperInvariant.invariant(getArgs(), y);
        actual;
        y;
    }

    function testFuzzInvariant(
        uint256 quote,
        uint256 asset,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public {
        HelperInvariant.Args memory args = HelperInvariant.Args(
            _base(asset),
            _strike(strike),
            _sigma(sigma),
            _tau(tau, block.timestamp)
        );

        console.log(args.x);
        console.log(args.K);
        console.log(args.o);
        console.log(args.t);
        int256 k = HelperInvariant.invariant(args, _quote(quote, args.K));
        if (args.t == 0) {
            int256 expected = int256(
                (args.K * (uint256(Invariant.ONE) - args.x)) / 1e18
            );
            assertEq(k, expected);
        }
        emit log_int(k);
    }
}
