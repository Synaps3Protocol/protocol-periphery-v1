// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { AccessAgg } from "contracts/aggregation/AccessAgg.sol";

contract DeployAccessAgg is DeployBase {
    function run() external returns (address agreementPortal) {
        vm.startBroadcast(getAdminPK());
        address accessManager = vm.envAddress("ACCESS_MANAGER");
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");

        address impl = address(new AccessAgg(rightsPolicyManager));
        bytes memory init = abi.encodeCall(AccessAgg.initialize, (accessManager));
        agreementPortal = deployUUPS(impl, init, "SALT_ACCESS_AGG");
        vm.stopBroadcast();

        _checkExpectedAddress(agreementPortal, "SALT_ACCESS_AGG");
        _logAddress("ACCESS_AGG", agreementPortal);
    }
}
