// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Invariant.sol";

library HelperInvariant {
    struct Args {
        uint256 x;
        uint256 K;
        uint256 o;
        uint256 t;
    }

    function getY(Args memory args) public pure returns (uint256 y) {
        y = Invariant.getY(args.x, args.K, args.o, args.t, 0);
    }

    function getX(Args memory args) public pure returns (uint256 x) {
        x = Invariant.getX(args.x, args.K, args.o, args.t, 0);
    }

    function invariant(Args memory args, uint256 R_y)
        public
        pure
        returns (int256 inv)
    {
        inv = Invariant.invariant(R_y, args.x, args.K, args.o, args.t);
    }
}
