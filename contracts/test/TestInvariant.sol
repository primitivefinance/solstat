// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Invariant.sol";

contract TestInvariant {
    struct Args {
        int256 x;
        int256 K;
        int256 o;
        int256 t;
    }

    function getY(Args memory args) public view returns (int256) {
        return Invariant.getY(args.x, args.K, args.o, args.t);
    }

    function getX(Args memory args) public view returns (int256) {
        return Invariant.getX(args.x, args.K, args.o, args.t);
    }

    function invariant(int256 y, Args memory args)
        public
        view
        returns (int256)
    {
        return Invariant.invariant(y, args.x, args.K, args.o, args.t);
    }
}
