// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { UpgradeBase } from "script/upgrades/00_Upgrade_Base.s.sol";
import { SubscriptionPolicy } from "contracts/policies/SubscriptionPolicy.sol";

contract UpgradeSubscriptionPolicy is UpgradeBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());
        address assetOwnership = vm.envAddress("ASSET_OWNERSHIP");
        address easAddress = vm.envAddress("EAS_ATTESTATION_PROVIDER");
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");
        address rightsAuthorizer = vm.envAddress("RIGHT_POLICY_AUTHORIZER");

        SubscriptionPolicy impl = new SubscriptionPolicy(
            rightsPolicyManager,
            rightsAuthorizer,
            assetOwnership,
            easAddress
        );

        address subscriptionProxy = vm.envAddress("SUBSCRIPTION_POLICY");
        // address accessManager = vm.envAddress("ACCESS_MANAGER");
        //!IMPORTANT: This is not a safe upgrade, take any caution or 2-check needed before run this method
        address subscriptionPolicy = upgradeAndCallUUPS(subscriptionProxy, address(impl), ""); // no initialization
        vm.stopBroadcast();
        return subscriptionPolicy;
    }
}
