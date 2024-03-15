// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Ownable } from "openzeppelin/access/Ownable.sol";

contract SponsorEscrow is Ownable {
  string public name;

  constructor(string memory _name)
    Ownable(_msgSender())
  {
    name = _name;
  }
}
