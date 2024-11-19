// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import { IStakeManager } from "@account-abstraction/contracts/interfaces/IStakeManager.sol";
import { console } from "forge-std/console.sol";

interface IERC4337Factory {
    function createAccount(address owner, bytes32 salt) external payable returns (address);
}

contract OpsCreateAccount is Script {
    function run() external {
        uint256 admin = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(admin);

        bytes32 salt = bytes32(abi.encodePacked(vm.addr(admin)));
        address factory = vm.envAddress("ACCOUNT_FACTORY");
        IERC4337Factory(factory).createAccount(vm.addr(admin), salt);
        vm.stopBroadcast();
    }
}
