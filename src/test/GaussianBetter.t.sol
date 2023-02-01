// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../reference/AssemblyGaussian.sol";
import {Gaussian as GaussianBetter} from "../Gaussian.sol";

import {Invariant} from "../reference/AssemblyInvariant.sol";
import {Invariant as InvariantBetter} from "../Invariant.sol";

import "../CFRMM.sol";

contract TestGaussianBetter is Test {
    function testCdfInverses() public {
        int256 x = 0.5 ether;
        int256 input = GaussianBetter.ppf(0.5 ether);
        int256 output = GaussianBetter.cdf(input);
        console.log("x");
        console.logInt(x);
        console.log("icdf(x)");
        console.logInt(input);
        console.log("cdf(icdf(x))");
        console.logInt(output);

        input = Gaussian.ppf(0.5 ether);
        output = Gaussian.cdf(input);
        console.log("x");
        console.logInt(x);
        console.log("icdf(x)");
        console.logInt(input);
        console.log("cdf(icdf(x))");
        console.logInt(output);
    }

    function testGaussianGas() public logs_gas {
        int256 z = Gaussian.cdf(int256(0.5 ether));
        z;
    }

    function testGaussianBetterGas() public logs_gas {
        int256 z = GaussianBetter.cdf(int256(0.5 ether));
        z;
    }

    function testCompareGaussian_cdf() public {
        uint256 x = 0.5 ether;
        int256 ref = Gaussian.cdf(int256(x));
        int256 actual = GaussianBetter.cdf(int256(x));
        int256 difference = actual - ref;
        int256 real = 0.691462461274013104 ether;
        console.log("==ref==");
        console.logInt(ref);
        console.log("==better==");
        console.logInt(actual);
        console.log("==diff==");
        console.logInt(difference);
        console.log("==real==");
        console.logInt(real);
    }

    function testCompareGaussian_ppf() public {
        uint256 x = 0.15 ether;
        int256 ref = Gaussian.ppf(int256(x));
        int256 actual = GaussianBetter.ppf(int256(x));
        int256 difference = actual - ref;
        int256 real = -int256(1.03643338949378958 ether);
        console.log("==ref==");
        console.logInt(ref);
        console.log("==better==");
        console.logInt(actual);
        console.log("==diff==");
        console.logInt(difference);
        console.log("==real==");
        console.logInt(real);
    }

    function testFuzz_ppf(int256 x) public {
        x = bound(x, 1, 1 ether - 1);
        int256 ref = Gaussian.ppf(x);
        int256 actual = GaussianBetter.ppf(x);
        assertApproxEqAbs(actual, ref, 1e12, "not equal");
    }

    function testCompareInvariant() public {
        uint256 price = 10 ether;
        uint256 strike = 10 ether;
        uint256 vol = 1 ether;
        uint256 tau = 31556952;
        uint256 x = 0.5 ether;
        uint256 ref = Invariant.getY(x, strike, vol, tau, 0);
        console.logInt(Gaussian.ppf(int256(1 ether) - int256(x)));
        console.logInt(GaussianBetter.ppf(int256(1 ether) - int256(x)));
        console.log("here", ref);
        uint256 actual = InvariantBetter.getY(x, strike, vol, tau, 0);
        console.log("actual", actual);
        uint256 real = 1.58655253931457051 ether;
        int256 difference = int256(actual) - int256(ref);
        console.log("======getY======");
        console.log("==ref==");
        console.log(ref);
        console.log("==better==");
        console.log(actual);
        console.log("==diff==");
        console.logInt(difference);
        console.log("==real==");
        console.log(real);

        ref = Invariant.getX(ref, strike, vol, tau, 0);
        actual = InvariantBetter.getX(actual, strike, vol, tau, 0);
        real = x;
        difference = int256(actual) - int256(ref);
        console.log("======getX======");
        console.log("==ref==");
        console.log(ref);
        console.log("==better==");
        console.log(actual);
        console.log("==diff==");
        console.logInt(difference);
        console.log("==real==");
        console.log(real);
    }

    function testCompare_getX_getY() public {}

    function testPrices() public {
        uint256 price = 10 ether;
        uint256 strike = 10 ether;
        uint256 vol = 10_000;
        uint256 tau = 31556952;
        uint256 x = 0.532 ether;
        uint256 getXWP = CFRMM.getXWithPrice(price, strike, vol, tau);
        uint256 getXWPRef = CFRMM.getXWithPriceReference(
            price,
            strike,
            vol,
            tau
        );
        uint256 real = 0.308537538725986896 ether;
        console.log("ref");
        console.log("getXWP", getXWPRef);

        console.log("got here");
        console.log("getXWP", getXWP);

        console.log("real");
        console.log("getXWP", real);

        uint256 getPWX = CFRMM.getPriceWithX(x, strike, vol, tau);
        uint256 getPWXRef = CFRMM.getPriceWithXReference(x, strike, vol, tau);
        console.log("======Prices======");
        console.log("==getPriceWithX ref==");
        console.log(getPWXRef);
        console.log("==getPriceWithX==");
        console.log(getPWX);
        console.log("real");
        //console.log(price);
        console.log(uint256(5.5973136657477859770 ether));
        uint256 thenGetX = CFRMM.getXWithPrice(getPWX, strike, vol, tau);
        console.log(thenGetX);
        // 0.3085375 41487717195
        // 0.3085375 38725986896
        // desired: 3085375 16918602067
    }

    function testCFRMM_inverses() public {
        uint256 price = 10 ether;
        uint256 strike = 10 ether;
        uint256 vol = 10_000;
        uint256 tau = 31556952;
        uint256 getXWP = CFRMM.getXWithPrice(price, strike, vol, tau);
        uint256 getPWX = CFRMM.getPriceWithX(getXWP, strike, vol, tau);
        console.log("x:", getXWP);
        console.log("p:", getPWX);
        console.log("x2", CFRMM.getXWithPrice(getPWX, strike, vol, tau));
    }
}
