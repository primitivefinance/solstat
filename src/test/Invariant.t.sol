// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Invariant} from "src/Invariant.sol";
import {Invariant as Ref} from "src/reference/ReferenceInvariant.sol";
import {HelperInvariant} from "src/test/HelperInvariant.sol";

contract TestInvariant is Test {
    function testReference_getY_Equality(
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

        uint256 actual = Invariant.getY(args.x, args.K, args.o, args.t, 0);
        uint256 expected = Ref.getY(args.x, args.K, args.o, args.t, 0);
        assertEq(actual, expected, "getY-inequality");
    }

    function testReference_getX_Equality(
        uint256 quote,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public {
        strike = _strike(strike);
        sigma = _sigma(sigma);
        tau = _tau(tau, block.timestamp);
        quote = _quote(quote, strike);
        HelperInvariant.Args memory args = HelperInvariant.Args(
            quote,
            strike,
            sigma,
            tau
        );

        uint256 actual = Invariant.getX(args.x, args.K, args.o, args.t, 0);
        uint256 expected = Ref.getX(args.x, args.K, args.o, args.t, 0);
        assertEq(actual, expected, "getX-inequality");
    }

    function testReference_invariant_Equality(
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

        quote = _quote(quote, strike);

        int256 actual = Invariant.invariant(
            quote,
            args.x,
            args.K,
            args.o,
            args.t
        );
        int256 expected = Ref.invariant(quote, args.x, args.K, args.o, args.t);
        assertEq(actual, expected, "invariant-inequality");
    }

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
        return bound(tau, time, (type(uint32).max - 1)); // Between block.timestamp and 2^32 - 1, in units of years.
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
        uint256 y = 308537538726e6;
        HelperInvariant.Args memory args = getArgs();
        args.x = y;
        uint256 actual = HelperInvariant.getX(args);
        actual;
    }

    function testHelperInvariantGas() public logs_gas {
        uint256 y = 308537538726e6;
        int256 actual = HelperInvariant.invariant(getArgs(), y);
        actual;
        y;
    }

    function testReferenceGetYGas() public logs_gas {
        HelperInvariant.Args memory args = getArgs();
        uint256 actual = Ref.getY(args.x, args.K, args.o, args.t, 0);
        actual;
    }

    function testReferenceGetXGas() public logs_gas {
        uint256 y = 308537538726e6;
        HelperInvariant.Args memory args = getArgs();
        uint256 actual = Ref.getX(y, args.K, args.o, args.t, 0);
        actual;
    }

    function testReferenceHelperInvariantGas() public logs_gas {
        uint256 y = 308537538726e6;
        HelperInvariant.Args memory args = getArgs();
        int256 actual = Ref.invariant(y, args.x, args.K, args.o, args.t);
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
        console.log("block time", block.timestamp);
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
