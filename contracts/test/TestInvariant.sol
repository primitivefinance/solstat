// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Invariant.sol";

contract TestInvariant {
    function getY(Invariant.Args memory args) public view returns (uint256) {
        return Invariant.getY(args.x, args.K, args.o, args.t);
    }

    function getX(Invariant.Args memory args) public view returns (uint256) {
        return Invariant.getX(args.x, args.K, args.o, args.t);
    }

    function invariant(uint256 y, Invariant.Args memory args)
        public
        view
        returns (int256)
    {
        return Invariant.invariant(y, args.x, args.K, args.o, args.t);
    }
}
