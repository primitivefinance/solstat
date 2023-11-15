// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../Gaussian.sol";
import {Invariant} from "../Invariant.sol";
import {Invariant as Ref} from "../reference/ReferenceInvariant.sol";
import {HelperInvariant} from "./HelperInvariant.sol";

uint256 constant GET_REVERSE_ERROR_REL = 0.000000988606022657 ether; //0.038844859616646632 ether; // highest % error found in test
uint256 constant GET_Y_ERROR_REL = 0.000000059885406089 ether; // highest % error found in test getY-0.5-365-days.
uint256 constant GET_X_ERROR_REL = 0.000000059885406087 ether; // highest % error found in test getX-0.5-365-days.

/// @dev for making test cases with different days, compute years in wad, then pass into calculator.
function debugDays(uint256 amountTime) pure returns (uint256 yearsWad) {
    yearsWad = (uint256(amountTime) * Invariant.WAD) / uint256(Invariant.YEAR);
}

function debugVol(uint256 amountVol) pure returns (uint256 yearsWad) {
    yearsWad = (uint256(amountVol) * Invariant.WAD) / 10_000;
}

function convertSecondsToWadYears(uint256 sec) pure returns (uint256 yrsWad) {
    uint256 wad = Invariant.WAD;
    uint256 yr = uint256(Invariant.YEAR);
    assembly {
        yrsWad := div(mul(sec, wad), yr)
    }
}

/**
 * @notice Changes percentage into WAD units then cancels the percentage units.
 */
function convertPercentageToWad(uint256 pct) pure returns (uint256 pctWad) {
    uint256 wad = Invariant.WAD;
    assembly {
        pctWad := div(mul(pct, wad), 10000)
    }
}

contract TestInvariant is Test {
    function testReverse() public {
        uint256 R_x = 0.460185342615210335 ether;
        uint256 stk = 10 ether;
        uint256 vol = 0.1 ether;
        uint256 tau = 365 days;
        int256 inv = 0;
        uint256 R_y = Ref.getY({
            R_x: R_x,
            stk: stk,
            vol: vol,
            tau: tau,
            inv: inv
        });

        uint256 expected = Ref.getX({
            R_y: R_y,
            stk: stk,
            vol: vol,
            tau: tau,
            inv: inv
        });

        assertApproxEqRel(
            R_y,
            5 ether,
            GET_REVERSE_ERROR_REL,
            "R_x-equals-strike"
        );
        assertApproxEqRel(
            R_x,
            expected,
            GET_REVERSE_ERROR_REL,
            "getY-getX-reverse"
        );
    }

    function testFuzzReverse(
        uint256 R_x,
        uint256 stk,
        uint256 vol,
        uint256 tau
    ) public {
        R_x = bound(R_x, 1_000_000_000_000 wei, 1 ether);
        stk = bound(stk, 1_000_000_000_000 wei, type(uint128).max - 1);
        vol = bound(vol, 0.01 ether, 2.5 ether); // 1% and 250%
        tau = bound(tau, 1 days, 500 days);

        uint256 R_y = Invariant.getY({
            R_x: R_x,
            stk: stk,
            vol: vol,
            tau: tau,
            inv: 0
        });
        vm.assume(R_y > 0);

        console.log("R_y", R_y);
        console.log("R_x", R_x);
        console.log("stk", stk);
        console.log("vol", vol);
        console.log("tau", tau);

        int256 phi;
        int256 one = 1 ether;
        assembly {
            phi := sdiv(mul(add(R_y, 0), one), stk) // (y + k) / K.
        }
        console.logInt(phi);

        uint256 expected = Invariant.getX({
            R_y: R_y,
            stk: stk,
            vol: vol,
            tau: tau,
            inv: 0
        });

        if (R_y == 0) expected = R_x;
        if (phi == Invariant.ONE) expected = 0;
        vm.assume(phi != Invariant.ONE);
        if (phi == 0) expected = Invariant.WAD;

        assertApproxEqRel(
            R_x,
            expected,
            GET_REVERSE_ERROR_REL,
            "getY-getX-equality"
        );
    }

    /// @dev `x = 1 - Φ(Φ⁻¹( (y + k) / K ) + σ√τ)`
    /// calculator: 1 - normalcdlower(normalicdlower({R_y} / {stk}) + {vol}sqrt({debugDays(tau)}))
    /// https://keisan.casio.com/calculator
    function test_getX() public {
        int256 inv = 0;
        assertApproxEqRel(
            Invariant.getX({
                R_y: 5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 365 days, // 0.999336057550805286 years
                inv: inv
            }),
            0.460185342615210335 ether,
            GET_X_ERROR_REL,
            "getX-365-days"
        );
        assertApproxEqRel(
            Invariant.getX({
                R_y: 5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 1 days, // 0.002737907006988507 years
                inv: inv
            }),
            0.497912543516404356 ether,
            GET_X_ERROR_REL,
            "getX-1-days"
        );
        assertApproxEqRel(
            Invariant.getX({
                R_y: 5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 1 hours, // 0.000114079458624521 years
                inv: inv
            }),
            0.499573897866220608 ether,
            GET_X_ERROR_REL,
            "getX-1-hours"
        );
        assertApproxEqRel(
            Invariant.getX({
                R_y: 5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 10 minutes, // 0.000019013243104086 years
                inv: inv
            }),
            0.499826044504759416 ether,
            GET_X_ERROR_REL,
            "getX-10-minutes"
        );

        assertApproxEqRel(
            Invariant.getX({
                R_y: 0.000001 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            0.9999998540866343 ether,
            GET_X_ERROR_REL,
            "getX-0.000001"
        );
        assertApproxEqRel(
            Invariant.getX({
                R_y: 1.923115 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            0.787774373410884564 ether,
            GET_X_ERROR_REL,
            "getX-1.923115"
        );
        assertApproxEqRel(
            Invariant.getX({
                R_y: 8.125266343 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            0.16904834360300908 ether,
            GET_X_ERROR_REL,
            "getX-8.125266343"
        );
        assertApproxEqRel(
            Invariant.getX({
                R_y: 0.9888888888888 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            0.888240006888906376 ether,
            GET_X_ERROR_REL,
            "getX-0.9888888888888"
        );
    }

    /// @dev `y = KΦ(Φ⁻¹(1-x) - σ√τ) + k`
    /// calculator: {stk}*normalcdlower(normalicdlower(1-{R_x}) - {vol}sqrt({debugDays(tau)}))
    /// https://keisan.casio.com/calculator
    function test_getY() public {
        int256 inv = 0;
        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 365 days, // 0.999336057550805286 years
                inv: inv
            }),
            4.60185342615210335 ether,
            GET_Y_ERROR_REL,
            "getY-365-days"
        );
        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 1 days, // 0.002737907006988507 years
                inv: inv
            }),
            4.97912543516404356 ether,
            GET_Y_ERROR_REL,
            "getY-1-days"
        );
        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 1 hours, // 0.000114079458624521 years
                inv: inv
            }),
            4.99573897866220608 ether,
            GET_Y_ERROR_REL,
            "getY-1-hours"
        );
        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.5 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 10 minutes, // 0.000019013243104086 years
                inv: inv
            }),
            4.99826044504759416 ether,
            GET_Y_ERROR_REL,
            "getY-10-minutes"
        );

        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.234235235 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            7.43535169031051685 ether,
            GET_Y_ERROR_REL,
            "getY-0.234235235"
        );
        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.155634675745745 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            8.2687166403107352 ether,
            GET_Y_ERROR_REL,
            "getY-0.155634675745745"
        );
        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.8125266343 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            1.6904834360300908 ether,
            GET_Y_ERROR_REL,
            "getY-0.8125266343"
        );
        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.9888888888888 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            0.092057918358111211 ether,
            GET_Y_ERROR_REL,
            "getY-0.9888888888888"
        );

        assertApproxEqRel(
            Invariant.getY({
                R_x: 0.00000000002 ether,
                stk: 10 ether,
                vol: 0.1 ether,
                tau: 182.5 days, // 0.499668028775402643 years
                inv: inv
            }),
            9.99999999967851372 ether,
            GET_Y_ERROR_REL,
            "getY-0.00000000002"
        );
    }

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
        assertApproxEqAbs(actual, expected, 1 ether - 1e6, "getX-inequality");
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

    function test_getY_upper_bound_returns_zero() public {
        HelperInvariant.Args memory args = HelperInvariant.Args({
            x: Invariant.WAD,
            K: 10e18,
            o: 1e4,
            t: 365 days
        });
        uint256 actual = Invariant.getY(args.x, args.K, args.o, args.t, 0);
        assertEq(actual, 0, "not-zero");
    }

    function test_getY_lower_bound_returns_strike() public {
        HelperInvariant.Args memory args = HelperInvariant.Args({
            x: 0,
            K: 10e18,
            o: 1e4,
            t: 365 days
        });
        uint256 actual = Invariant.getY(args.x, args.K, args.o, args.t, 0);
        assertEq(actual, args.K, "not-strike");
    }
}
