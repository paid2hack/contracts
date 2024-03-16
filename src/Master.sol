// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { IMaster, Team } from "./IMaster.sol";
import "./Errors.sol";

struct Event {
  string name;
  address owner;
  uint[] teamIds;
  address[] sponsors;
}

/**
 * @dev Master contract holding all events and teams.
 */
contract Master is Ownable, IMaster {
  string public name;

  uint public totalEvents;
  // event id => event
  mapping(uint => Event) public events;
  // event id => sponsor => is a sponsor
  mapping(uint => mapping(address => bool)) public isSponsor;

  uint public totalTeams;
  // team id => team
  mapping(uint => Team) public teams;

  constructor() Ownable(_msgSender()) {}

  // Events

  function getEvent(uint _eventId) external view returns (Event memory) {
    return events[_eventId];
  }

  function createEvent(string memory _name) external {
    totalEvents++;
    events[totalEvents].name = _name;
    events[totalEvents].owner = _msgSender();
  }

  function updateEventName(uint _eventId, string calldata _name) external isEventCreator(_eventId) {
    events[_eventId].name = _name;
  }

  // Teams

  function getTeam(uint _teamId) external view returns (Team memory) {
    return teams[_teamId];
  }

  function getEventTeam (uint _eventId, uint _teamIndex) external view returns (uint teamId_, Team memory team_) {
    if (_teamIndex < events[_eventId].teamIds.length) {
      teamId_ = events[_eventId].teamIds[_teamIndex];
      team_ = teams[teamId_];
    }
  }

  function createTeam(uint _eventId, Team calldata _team) external isValidEvent(_eventId) {
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

  // Sponsors

  function getEventSponsor (uint _eventId, uint _sponsorIndex) external view returns (address) {
    return events[_eventId].sponsors[_sponsorIndex];
  }

  function addSponsor(uint _eventId, address _sponsor) external isValidEvent(_eventId) {
    if (isSponsor[_eventId][_sponsor]) {
      revert AlreadySponsoringEvent();
    }
    events[_eventId].sponsors.push(_sponsor);
    isSponsor[_eventId][_sponsor] = true;
  }

  // Modifiers

  modifier isValidEvent(uint _eventId) {
    if (_eventId > totalEvents) {
      revert InvalidEvent(_eventId);
    }
    _;
  }

  modifier isTeamLeader(uint _teamId) {
    if (teams[_teamId].leader != _msgSender()) {
      revert NotTeamLeader();
    }
    _;
  }

  modifier isEventCreator(uint _eventId) {
    if (events[_eventId].owner != _msgSender()) {
      revert NotEventCreator();
    }
    _;
  }
}

