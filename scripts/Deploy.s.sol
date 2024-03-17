// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

import { Script, console2 as c } from "forge-std/Script.sol";
import { ERC20Mock } from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import { Master } from "src/Master.sol";
import { Sponsor } from "src/Sponsor.sol";
import { Team } from "src/IMaster.sol";

contract DeployScript is Script {
  bytes32 internal constant CREATE2_SALT = keccak256("Paid2Hack.deployment.salt");
  
  function _assertDeployedAddressIsEmpty(bytes memory creationCode, bytes memory constructorArgs) internal view returns (address) {
    address expectedAddr = vm.computeCreate2Address(
      CREATE2_SALT, 
      hashInitCode(creationCode, constructorArgs)
    );

    if (expectedAddr.code.length > 0) {
      c.log("!!!! Already deployed at:", expectedAddr);
      revert("Already deployd");
    }

    return expectedAddr;
  }

  function run() public {
    address wallet = msg.sender;

    vm.startBroadcast(wallet);

    _assertDeployedAddressIsEmpty(type(Master).creationCode, abi.encode());

    c.log("Deploying Master...");
    Master m = new Master{salt: CREATE2_SALT}();
    c.log("Master deployed to: %s", address(m));

    c.log("Creating dummy event, team and sponsor...");
    m.createEvent("Event 1");
    m.createTeam(1, Team({
      name: "Team 1",
      leader: wallet,
      members: new address[](0)
    }));
    Sponsor s = new Sponsor(address(m), 1, "Sponsor 1");
    c.log("Dummy event, team and sponsor created");

    c.log("Deploying MockToken1...");
    ERC20Mock token1 = new ERC20Mock{salt: CREATE2_SALT}();
    token1.mint(address(s), 1000000 ether);
    token1.mint(wallet, 1000000 ether);
    c.log("MockToken1 deployed to: %s", address(token1));

    c.log("Allocating prizes...");
    address[] memory tokens = new address[](1);
    tokens[0] = address(token1);
    uint[] memory teamIds = new uint[](1);
    teamIds[0] = 1;
    uint[] memory amounts = new uint[](1);
    amounts[0] = 3 ether;
    s.allocatePrizes(tokens, teamIds, amounts);
    c.log("Prizes allocated");

    vm.stopBroadcast();        
  }
}