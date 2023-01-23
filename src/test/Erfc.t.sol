// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Gaussian} from "../Gaussian.sol";
import {Gaussian as GaussianRefs} from "../reference/ReferenceGaussian.sol";

contract ErfcTest is Test {

    /*
    int256 temp;
    function fastExp(uint256 n, int256 input) public returns (int256 output) {
        temp = input;

        assembly {
            function muli(x, y) -> res {
                res := sdiv(mul(x, y), 0xde0b6b3a7640000)
            }

            function fastExp(x) -> r {
                let e := 2718281828460000000

                r := 0xde0b6b3a7640000

                for { let i := sub(100, 1) } gt(i, 0) { i := sub(i, 1) } {
                    r := add(0xde0b6b3a7640000, div(muli(x, r), i))
                }
            }

            output := fastExp(10, sload(temp.slot))
        }
    }

    function test_fastExp() public {
        console.logInt(fastExp(100, 26 ether));
    }
    */


    /**
     *
     * float t,z,ans;
     * z=fabs(x);
     * t=1.0/(1.0+0.5*z);
     * ans=t*exp(-z*z-1.26551223+t*(1.00002368+t*(0.37409196+t*(0.09678418+
     * t*(-0.18628806+t*(0.27886807+t*(-1.13520398+t*(1.48851587+
     * t*(-0.82215223+t*0.17087277)))))))));
     * return x >= 0.0 ? ans : 2.0-ans;
     *
     */
    function clemerfc(int256 input) public pure returns (int256 output) {
        assembly {
            // TODO: Check if it's safe to avoid reverting
            if eq(input, 0x8000000000000000000000000000000000000000000000000000000000000000) { revert(0, 0) }

            // z = abs(input)
            let z := input
            if gt(z, 0x8000000000000000000000000000000000000000000000000000000000000000) {
                z := sub(0, z)
            }

            // t = 1 / (1 + z / 2)
            let t := div(mul(z, 0xde0b6b3a7640000), 0x1bc16d674ec80000)
            t := add(0xde0b6b3a7640000, z)
            t := div(0xde0b6b3a7640000, z)

            let invZ := sub(0, z)

            function fastExp(x) -> r {
                let e := 2718281828460000000
                r := 0xde0b6b3a7640000

                for { let i := sub(100, 1) } gt(i, 0) { i := sub(i, 1) } {
                    r := add(0xde0b6b3a7640000, div(muli(x, r), i))
                }
            }

            function muli(x, y) -> res {
                res := sdiv(mul(x, y), 0xde0b6b3a7640000)
            }

            output := muli(
                t,
                fastExp(
                    muli(
                        add(sub(muli(sub(0, z), z), 1265512230000000000), t),
                        muli(
                            add(1000023680000000000, t),
                            muli(
                                add(374091960000000000, t),
                                muli(
                                    add(96784180000000000, t),
                                    muli(
                                        add(0xfffffffffffffffffffffffffffffffffffffffffffffffffd6a2bff15cda800, t),
                                        muli(
                                            add(278868070000000000, t),
                                            muli(
                                                add(0xfffffffffffffffffffffffffffffffffffffffffffffffff03ef1fea87d8800, t),
                                                muli(
                                                    add(1488515870000000000, t),
                                                    muli(
                                                        add(0xfffffffffffffffffffffffffffffffffffffffffffffffff49720e71b8e0400, t),
                                                        170872770000000000
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )

            if gt(input, 0x8000000000000000000000000000000000000000000000000000000000000000) {
                output := sub(0x1bc16d674ec80000, output)
            }
        }
    }

    function clemAbs(int256 input) public pure returns (int256 output) {
        assembly {
            if eq(input, 0x8000000000000000000000000000000000000000000000000000000000000000) { revert(0, 0) }
            output := input
            if gt(output, 0x8000000000000000000000000000000000000000000000000000000000000000) {
                output := sub(0, output)
            }
        }
    }

    function test_clemerfc(int256 input) public {
        vm.assume(input > 1 ether || input < -1 ether);
        vm.assume(input != -57896044618658097711785492504343953926634992332820282019728792003956564819968);
        assertEq(Gaussian.erfc(input), clemerfc(input));
    }

    function test_erfc_zero() public {
        int256 output = Gaussian.erfc(0);
        assertEq(output, 1);
    }

    function test_erfc_negative(int256 input) public {
        vm.assume(input < 0);
        int256 output = Gaussian.erfc(input);
        int256 expected = 2 - Gaussian.erfc(input);
        assertApproxEqRel(output, expected, 5);
    }
}
