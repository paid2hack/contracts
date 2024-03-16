// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

struct Team {
  string name;
  address leader;
  address[] members;
}

interface IMaster {
  function addSponsor(uint _eventId, address _sponsor) external;
  function getTeam(uint _teamId) external view returns (Team calldata);
}