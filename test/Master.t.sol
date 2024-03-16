// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";

import { Master, Team, Event } from "../src/Master.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import "../src/Errors.sol";

contract MasterTest is Test {
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

  function test_createTeam() public {
    vm.prank(owner1);
    m.createEvent("Event 1");

    vm.prank(owner1);
    m.createTeam(1, Team({
      name: "Team 1",
      leader: owner1,
      members: new address[](0)
    }));

    assertEq(m.totalTeams(), 1);
    assertEq(m.getTeam(1).name, "Team 1");
    assertEq(m.getTeam(1).leader, owner1);

    (uint teamId_, Team memory team_) = m.getEventTeam(1, 0);
    assertEq(teamId_, 1);
    assertEq(team_.name, "Team 1");
    assertEq(team_.leader, owner1);
  }
}
