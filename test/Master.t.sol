// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";

import { Master } from "../src/Master.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";

contract NaymTokenTest is Test {
  Master public m;

  address owner1 = address(0x111);
  address owner2 = address(0x789);

  function setUp() public {
    m = new Master();
  }

  function test_createEvent() public {
    vm.prank(owner1);
    m.createEvent("Event 1");

    assertEq(m.totalEvents(), 1);
    assertEq(m.getEvent(1).name, "Event 1");
    assertEq(m.getEvent(1).owner, owner1);
  }
}
