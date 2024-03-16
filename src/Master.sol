// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

import { Ownable } from "openzeppelin/access/Ownable.sol";

struct Team {
  string name;
  address leader;
  address[] members;
}

struct Event {
  string name;
  address owner;
  uint[] teamIds;
}

error NotTeamLeader();
error NotEventCreator();

/**
 * @dev Master contract holding all events and teams.
 */
contract Master is Ownable {
  string public name;

  uint public totalEvents;
  mapping(uint => Event) public events;

  uint public totalTeams;
  mapping(uint => Team) public teams;

  constructor() Ownable(msg.sender) {}

  function getEvent(uint _eventId) external view returns (Event memory) {
    return events[_eventId];
  }

  function createEvent(string memory _name) external {
    totalEvents++;
    events[totalEvents].name = _name;
    events[totalEvents].owner = msg.sender;
  }

  function updateEventName(uint _eventId, string calldata _name) external isEventCreator(_eventId) {
    events[_eventId].name = _name;
  }

  function createTeam(uint _eventId, Team calldata _team) external {
    totalTeams++;
    teams[totalTeams] = _team;
    events[_eventId].teamIds.push(totalTeams);
  }

  function updateTeamMembers(uint _teamId, address[] calldata members) external isTeamLeader(_teamId) {
    teams[_teamId].members = members;
  }

  function updateTeamName(uint _teamId, string calldata _name) external isTeamLeader(_teamId) {
    teams[_teamId].name = _name;
  }

  // Modifiers

  modifier isTeamLeader(uint _teamId) {
    if (teams[_teamId].leader != msg.sender) {
      revert NotTeamLeader();
    }
    _;
  }

  modifier isEventCreator(uint _eventId) {
    if (events[_eventId].owner != msg.sender) {
      revert NotEventCreator();
    }
    _;
  }
}

