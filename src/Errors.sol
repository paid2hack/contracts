// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

error NotTeamLeader();
error NotEventCreator();
error InvalidInput();
error InvalidEvent(uint _eventId);
error InvalidTeam(uint _teamId);
error AlreadySponsoringEvent();
error NotEnoughFunds(address token);
error WithdrawalFailed(address token);
