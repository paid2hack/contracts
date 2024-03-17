// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { IMaster, Team } from "./IMaster.sol";
import { ISponsor } from "./ISponsor.sol";
import "./Errors.sol";

struct Prize {
  address[] tokens;
  // token => amount
  mapping(address => uint) amounts;
  // token => claimed amount
  mapping(address => uint) claimed;
}

/**
  TODO: Add timeout on prize allocations - if prize not claimed then sponsor can take the money back.
 */
contract Sponsor is Ownable, ISponsor {
  IMaster public master;
  string public name;
  uint public eventId;

  // team id => prize information
  mapping (uint => Prize) internal teamPrizes;
  // token => total prize allocated
  mapping (address => uint) public totalTokenPrizeAmounts;
  // amounts claimed: team member => token => amount
  mapping (address => mapping(address => uint)) public claimedAmounts;
  // token => total claimed
  mapping(address => uint) public totalClaimedAmounts;

  constructor(address _master, uint _eventId, string memory _name)
    Ownable(_msgSender())
  {
    master = IMaster(_master);
    name = _name;
    eventId = _eventId;
    master.addSponsor(eventId, address(this));
  }

  function updateName(string calldata _name) external onlyOwner {
    name = _name;
  }

  function allocatePrizes(address[] calldata _tokens, uint[] calldata _teamIds, uint[] calldata _amounts) external onlyOwner {
    if (_tokens.length != _teamIds.length || _tokens.length != _amounts.length) {
      revert InvalidInput();
    }

    for (uint i = 0; i < _tokens.length; i++) {
      _allocatePrize(_tokens[i], _teamIds[i], _amounts[i]);
    }
  }

  function _allocatePrize(address _token, uint _teamId, uint _amount) private {
    IERC20 t = IERC20(_token);

    Team memory team = master.getTeam(_teamId);
    if (team.leader == address(0)) {
      revert InvalidTeam(_teamId);
    }

    uint fundsAvailable = 0;
    uint f = totalTokenPrizeAmounts[_token] + _amount;
    if (f >= totalClaimedAmounts[_token]) {
      fundsAvailable = f - totalClaimedAmounts[_token];
    }
    if (fundsAvailable > t.balanceOf(address(this))) {
      revert NotEnoughFunds(_token);
    } else {
      totalTokenPrizeAmounts[_token] += _amount;
      teamPrizes[_teamId].amounts[_token] += _amount;
      bool inTokenList = false;
      for (uint i = 0; i < teamPrizes[_teamId].tokens.length; i++) {
        if (teamPrizes[_teamId].tokens[i] == _token) {
          inTokenList = true;
          break;
        }
      }
      if (!inTokenList) {
        teamPrizes[_teamId].tokens.push(_token);
      }      
    }
  }

  function getPrizeTokens(uint _teamId) external view returns (address[] memory) {
    return teamPrizes[_teamId].tokens;
  }

  function getPrizeAmount(uint _teamId, address _token) external view returns (uint) {
    return teamPrizes[_teamId].amounts[_token];
  }

  function getClaimedAmount(uint _teamId, address _token) external view returns (uint) {
    return teamPrizes[_teamId].claimed[_token];
  }

  function getAllocatablePrize(address _token) external view returns (uint amount_) {
    uint bal = IERC20(_token).balanceOf(address(this)) + totalClaimedAmounts[_token]; 
    if (bal >= totalTokenPrizeAmounts[_token]) {
      amount_ = bal - totalTokenPrizeAmounts[_token];
    }
  }

  function getClaimablePrize(uint _teamId, address _claimant, address _token) public view returns (uint amountLeft_) {
    Team memory t = master.getTeam(_teamId);
    bool canClaim = (t.leader == _claimant);
    if (!canClaim) {
      for (uint i = 0; i < t.members.length; i++) {
        if (t.members[i] == _claimant) {
          canClaim = true;
          break;
        }
      }
    }
    if (canClaim) {
      uint perPerson = teamPrizes[_teamId].amounts[_token] / (1 + t.members.length);
      if (perPerson >= claimedAmounts[_claimant][_token]) {
        amountLeft_ = perPerson - claimedAmounts[_claimant][_token];
      }
    }
  }

  function claimPrize(uint _teamId, address _token, address _claimant) external {
    uint a = getClaimablePrize(_teamId, _claimant, _token);

    if (a > 0) {
      claimedAmounts[_claimant][_token] += a;
      teamPrizes[_teamId].claimed[_token] += a;
      totalClaimedAmounts[_token] += a;

      IERC20 t = IERC20(_token);
      if (!t.transfer(_claimant, a)) {
        revert WithdrawalFailed(_token);
      }
    }
  }
}
