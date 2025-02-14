// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { UpgradeBase } from "script/upgrades/00_Upgrade_Base.s.sol";
import { AccessAgg } from "contracts/aggregation/AccessAgg.sol";

contract DeployAccessAgg is UpgradeBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");
        address impl = address(new AccessAgg(rightsPolicyManager));
        address accessAggregatorProxy = vm.envAddress("ACCESS_AGG");

        // address accessManager = vm.envAddress("ACCESS_MANAGER");
        //!IMPORTANT: This is not a safe upgrade, take any caution or 2-check needed before run this method
        address accessAggregator = upgradeAndCallUUPS(accessAggregatorProxy, address(impl), ""); // no initialization
        vm.stopBroadcast();
        return accessAggregator;

    }
}
