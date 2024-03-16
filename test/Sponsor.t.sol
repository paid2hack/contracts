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

    m.createTeam(1, Team({
      name: "Team 2",
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

    address[] memory tokens = new address[](1);
    tokens[0] = address(token1);

    uint[] memory teamIds = new uint[](1);
    teamIds[0] = 1;

    uint[] memory amounts = new uint[](1);
    amounts[0] = 100;

    vm.prank(owner2);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner2));
    s.allocatePrizes(tokens, teamIds, amounts);
  }

  function test_Sponsor_AllocatePrizes_NotEnoughFunds() public {
    Sponsor s = _createEventTeamSponsor();

    address[] memory tokens = new address[](1);
    tokens[0] = address(token1);

    uint[] memory teamIds = new uint[](1);
    teamIds[0] = 1;

    uint[] memory amounts = new uint[](1);
    amounts[0] = 100;

    vm.prank(owner1);
    vm.expectRevert(abi.encodeWithSelector(NotEnoughFunds.selector, address(token1)));
    s.allocatePrizes(tokens, teamIds, amounts);
  }

  function test_Sponsor_AllocatePrizes_InvalidTeam() public {
    Sponsor s = _createEventTeamSponsor();

    token1.mint(address(s), 133);

    address[] memory tokens = new address[](1);
    tokens[0] = address(token1);

    uint[] memory teamIds = new uint[](1);
    teamIds[0] = 3;

    uint[] memory amounts = new uint[](1);
    amounts[0] = 100;

    vm.prank(owner1);
    vm.expectRevert(abi.encodeWithSelector(InvalidTeam.selector, 3));
    s.allocatePrizes(tokens, teamIds, amounts);
  }

  function test_Sponsor_AllocatePrizes() public returns (Sponsor) { 
    Sponsor s = _createEventTeamSponsor();

    token1.mint(address(s), 120);
    token2.mint(address(s), 270);

    vm.startPrank(owner1);

    address[] memory tokens = new address[](2);
    tokens[0] = address(token1);
    tokens[1] = address(token2);

    uint[] memory teamIds = new uint[](2);
    teamIds[0] = 1;
    teamIds[1] = 1;

    uint[] memory amounts = new uint[](2);
    amounts[0] = 90;
    amounts[1] = 150;

    s.allocatePrizes(tokens, teamIds, amounts);

    teamIds[0] = 2;
    teamIds[1] = 2;

    amounts[0] = 30;
    amounts[1] = 120;

    s.allocatePrizes(tokens, teamIds, amounts);

    vm.stopPrank(); 

    assertEq(s.getPrizeTokens(1).length, 2);
    assertEq(s.getPrizeTokens(1)[0], address(token1));
    assertEq(s.getPrizeTokens(1)[1], address(token2));
    assertEq(s.getPrizeAmount(1, address(token1)), 90);
    assertEq(s.getPrizeAmount(1, address(token2)), 150);

    assertEq(s.getPrizeTokens(2).length, 2);
    assertEq(s.getPrizeTokens(2)[0], address(token1));
    assertEq(s.getPrizeTokens(2)[1], address(token2));
    assertEq(s.getPrizeAmount(2, address(token1)), 30);
    assertEq(s.getPrizeAmount(2, address(token2)), 120);

    assertEq(s.totalTokenPrizeAmounts(address(token1)), 120);
    assertEq(s.totalTokenPrizeAmounts(address(token2)), 270);

    return s;
  }

  function test_Sponsor_GetTotalPrizeViaMaster() public {
    test_Sponsor_AllocatePrizes();
    assertEq(m.getTotalSponsorPrize(1, address(token1)), 120);
    assertEq(m.getTotalSponsorPrize(1, address(token2)), 270);
  }

  function test_Sponsor_GetClaimablePrize() public {
    Sponsor s = test_Sponsor_AllocatePrizes();

    // team 1 prizes - split between 3 claimaints
    assertEq(s.getClaimablePrize(1, owner1, address(token1)), 0);
    assertEq(s.getClaimablePrize(1, owner2, address(token1)), 90 / 3);
    assertEq(s.getClaimablePrize(1, owner3, address(token1)), 90 / 3);
    assertEq(s.getClaimablePrize(1, owner4, address(token1)), 90 / 3);
    assertEq(s.getClaimablePrize(1, owner1, address(token2)), 0);
    assertEq(s.getClaimablePrize(1, owner2, address(token2)), 150 / 3);
    assertEq(s.getClaimablePrize(1, owner3, address(token2)), 150 / 3);
    assertEq(s.getClaimablePrize(1, owner4, address(token2)), 150 / 3);

    // team 2 prizes - split between 3 claimaints
    assertEq(s.getClaimablePrize(2, owner1, address(token1)), 0);
    assertEq(s.getClaimablePrize(2, owner2, address(token1)), 30 / 3);
    assertEq(s.getClaimablePrize(2, owner3, address(token1)), 30 / 3);
    assertEq(s.getClaimablePrize(2, owner4, address(token1)), 30 / 3);
    assertEq(s.getClaimablePrize(2, owner1, address(token2)), 0);
    assertEq(s.getClaimablePrize(2, owner2, address(token2)), 120 / 3);
    assertEq(s.getClaimablePrize(2, owner3, address(token2)), 120 / 3);
    assertEq(s.getClaimablePrize(2, owner4, address(token2)), 120 / 3);
  }

  function test_Sponsor_ClaimPrize_NoneOwed() public {
    Sponsor s = test_Sponsor_AllocatePrizes();

    s.claimPrize(1, address(token1), owner1);

    assertEq(token1.balanceOf(owner1), 0);    
    assertEq(token1.balanceOf(address(s)), 120);
  }

  function test_Sponsor_ClaimPrize() public {
    Sponsor s = test_Sponsor_AllocatePrizes();

    s.claimPrize(1, address(token1), owner2);
    s.claimPrize(1, address(token2), owner2);

    assertEq(s.claimedAmounts(owner2, address(token1)), 90 / 3);
    assertEq(s.claimedAmounts(owner2, address(token2)), 150 / 3);
    assertEq(s.totalClaimedAmounts(address(token1)), 90 / 3);
    assertEq(s.totalClaimedAmounts(address(token2)), 150 / 3);

    assertEq(s.getClaimablePrize(1, owner1, address(token1)), 0);
    assertEq(s.getClaimablePrize(1, owner2, address(token1)), 0);
    assertEq(s.getClaimablePrize(1, owner3, address(token1)), 90 / 3);
    assertEq(s.getClaimablePrize(1, owner4, address(token1)), 90 / 3);
    assertEq(s.getClaimablePrize(1, owner1, address(token2)), 0);
    assertEq(s.getClaimablePrize(1, owner2, address(token2)), 0);
    assertEq(s.getClaimablePrize(1, owner3, address(token2)), 150 / 3);
    assertEq(s.getClaimablePrize(1, owner4, address(token2)), 150 / 3);

    assertEq(token1.balanceOf(owner2), 90 / 3);
    assertEq(token2.balanceOf(owner2), 150 / 3);

    assertEq(token1.balanceOf(address(s)), 120 - 90 / 3);
    assertEq(token2.balanceOf(address(s)), 270 - 150 / 3);
  }

  function test_Sponsor_ClaimPrize_AfterNewPrizeAllocated() public {
    Sponsor s = test_Sponsor_AllocatePrizes();

    s.claimPrize(1, address(token1), owner2);

    assertEq(s.claimedAmounts(owner2, address(token1)), 90 / 3);
    assertEq(s.totalClaimedAmounts(address(token1)), 90 / 3);

    assertEq(token1.balanceOf(owner2), 90 / 3);
    assertEq(token1.balanceOf(address(s)), 120 - 90 / 3);

    token1.mint(address(s), 300);

    vm.prank(owner1);

    address[] memory tokens = new address[](1);
    tokens[0] = address(token1);

    uint[] memory teamIds = new uint[](1);
    teamIds[0] = 1;

    uint[] memory amounts = new uint[](1);
    amounts[0] = 300;

    s.allocatePrizes(tokens, teamIds, amounts);

    assertEq(s.getClaimablePrize(1, owner2, address(token1)), 300 / 3);

    s.claimPrize(1, address(token1), owner2);

    assertEq(s.claimedAmounts(owner2, address(token1)), 90 / 3 + 100);
    assertEq(s.totalClaimedAmounts(address(token1)), 90 / 3 + 100);

    assertEq(token1.balanceOf(owner2), 90 / 3 + 100);
    assertEq(token1.balanceOf(address(s)), 120 - 90 / 3 + 200);
  }

  function test_Sponsor_GetAllocatablePrize() public {
    Sponsor s = test_Sponsor_AllocatePrizes();

    assertEq(s.getAllocatablePrize(address(token1)), 0);
    assertEq(s.getAllocatablePrize(address(token2)), 0);

    token1.mint(address(s), 100);
    token2.mint(address(s), 200);

    assertEq(s.getAllocatablePrize(address(token1)), 100);
    assertEq(s.getAllocatablePrize(address(token2)), 200);

    s.claimPrize(1, address(token1), owner2);

    assertEq(s.getAllocatablePrize(address(token1)), 100);
  }
}
