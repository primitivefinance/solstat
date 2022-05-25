// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/Example.sol";

contract TestExample is Test {
    Example public ex;

    function setUp() public payable {
        ex = new Example();
        vm.prank(address(0));
        vm.deal(address(0), 100 ether);
    }

    function testReceive() public payable {
        address(payable(ex)).call{value: 1 ether}("");
        assert(address(ex).balance == 1 ether);
    }
}
