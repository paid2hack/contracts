// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.24;

import { Script, console2 as c } from "forge-std/Script.sol";
import { Master } from "src/Master.sol";

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

    Master master = new Master{salt: CREATE2_SALT}();
    c.log("Master deployed to: %s", address(master));

    vm.stopBroadcast();        
  }
}