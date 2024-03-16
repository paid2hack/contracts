// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ERC20Mock } from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";

import { Master, Event } from "../src/Master.sol";
import { Team } from "../src/IMaster.sol";
import { Prize, Sponsor } from "../src/Sponsor.sol";
import "../src/Errors.sol";

contract SponsorTest is Test {
  Master public m;
  ERC20Mock token1;
  ERC20Mock token2;

  address owner1 = address(0x111);
  address owner2 = address(0x789);
  address owner3 = address(0x222);
  address owner4 = address(0x333);

  function setUp() public {
    m = new Master();
    token1 = new ERC20Mock();
    token2 = new ERC20Mock();
  }

  function test_AddSponsor_InvalidEvent() public {
    vm.prank(owner1);
    vm.expectRevert(abi.encodeWithSelector(InvalidEvent.selector, 1));
    new Sponsor(address(m), 1, "Sponsor 1");
  }

  function test_AddSponsor_ValidEvent() public {
    vm.prank(owner1);
    m.createEvent("Event 1");

    Sponsor s = new Sponsor(address(m), 1, "Sponsor 1");

    assertEq(m.isSponsor(1, address(s)), true);

    Event memory e = m.getEvent(1);
    assertEq(e.sponsors.length, 1);
    assertEq(e.sponsors[0], address(s));
  }

  function _createEventTeamSponsor() internal returns (Sponsor) {
    vm.startPrank(owner1);
    
    m.createEvent("Event 1");

    address[] memory members = new address[](2);
    members[0] = owner3;
    members[1] = owner4;

    m.createTeam(1, Team({
      name: "Team 1",
      leader: owner2,
      members: members
    }));

    Sponsor s = new Sponsor(address(m), 1, "Sponsor 1");

    vm.stopPrank();

    return s;
  }

  function test_Sponsor_UpdateName() public {
    Sponsor s = _createEventTeamSponsor();

    vm.prank(owner1);
    s.updateName("Sponsor 2");

    assertEq(s.name(), "Sponsor 2");

    vm.prank(owner2);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner2));
    s.updateName("Sponsor 3");
  }

  function test_Sponsor_AllocatePrizes_NotOwner() public {
    Sponsor s = _createEventTeamSponsor();

    vm.prank(owner2);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner2));
    s.allocatePrize(address(token1), 1, 100);
  }

  function test_Sponsor_AllocatePrizes_NotEnoughFunds() public {
    Sponsor s = _createEventTeamSponsor();

    vm.prank(owner1);
    vm.expectRevert(abi.encodeWithSelector(NotEnoughFunds.selector, address(token1)));
    s.allocatePrize(address(token1), 1, 100);
  }

  function test_Sponsor_AllocatePrizes_InvalidTeam() public {
    Sponsor s = _createEventTeamSponsor();

    token1.mint(address(s), 133);
    token2.mint(address(s), 160);

    vm.prank(owner1);
    vm.expectRevert(abi.encodeWithSelector(InvalidTeam.selector, 2));
    s.allocatePrize(address(token1), 2, 100);
  }

  function test_Sponsor_AllocatePrizes() public {
    Sponsor s = _createEventTeamSponsor();

    token1.mint(address(s), 133);
    token2.mint(address(s), 160);

    vm.startPrank(owner1);
    s.allocatePrize(address(token1), 1, 100);
    s.allocatePrize(address(token2), 1, 150);
    s.allocatePrize(address(token1), 1, 33); // 133 total
    s.allocatePrize(address(token2), 1, 10); // 160 total
    vm.stopPrank(); 

    assertEq(s.getPrizeTokens(1).length, 2);
    assertEq(s.getPrizeTokens(1)[0], address(token1));
    assertEq(s.getPrizeTokens(1)[1], address(token2));
    assertEq(s.getPrizeAmount(1, address(token1)), 133);
    assertEq(s.getPrizeAmount(1, address(token2)), 160);

    assertEq(s.totalTokenPrizeAmounts(address(token1)), 133);
    assertEq(s.totalTokenPrizeAmounts(address(token2)), 160);
  }

  function test_Sponsor_GetClaimablePrize() public {
    test_Sponsor_AllocatePrizes();

    assertEq(s.getClaimablePrize(1, owner1, token1), 0);
  }
}
