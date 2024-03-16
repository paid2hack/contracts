// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

interface ISponsor {
  function totalTokenPrizeAmounts(address _token) external view returns (uint);
}