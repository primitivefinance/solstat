// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "../libraries/RayMathLib.sol" as RayMathLib;

contract TestRayMathLib is Test {
    function test_logfp() public {
        int256 x = 3.5e27;
        int256 y = RayMathLib.logfp(x);
        console.logInt(FixedPointMathLib.lnWad(3.5e18));
        assertEq(y, 1.25276296849536799568812062e27, "logfp-3.5e27");
    }
}
