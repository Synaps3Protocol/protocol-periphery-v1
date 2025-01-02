// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import { IStakeManager } from "@account-abstraction/contracts/interfaces/IStakeManager.sol";
import { console } from "forge-std/console.sol";

contract OpsFundPaymaster is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address paymaster = vm.envAddress("PAYMASTER");
        address entrypoint = vm.envAddress("ENTRYPOINT");
        uint256 deposit = vm.parseUint(vm.prompt("-> amount to deposit:"));
        IStakeManager(entrypoint).depositTo{ value: deposit * 1 ether }(paymaster);
        vm.stopBroadcast();
    }
}
