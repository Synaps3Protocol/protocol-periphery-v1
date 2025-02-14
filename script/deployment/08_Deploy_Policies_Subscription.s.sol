// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { SubscriptionPolicy } from "contracts/policies/SubscriptionPolicy.sol";

contract DeploySubscriptionPolicy is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());

        address accessManager = vm.envAddress("ACCESS_MANAGER");
        address assetOwnership = vm.envAddress("ASSET_OWNERSHIP");
        address easAddress = computeCreate3Address("SALT_ATTESTATION_EAS");
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");
        address rightsAuthorizer = vm.envAddress("RIGHT_POLICY_AUTHORIZER");

        SubscriptionPolicy impl = new SubscriptionPolicy(
            rightsPolicyManager,
            rightsAuthorizer,
            assetOwnership,
            easAddress
        );

        bytes memory init = abi.encodeCall(SubscriptionPolicy.initialize, (accessManager));
        address policy = deployUUPS(address(impl), init, "SALT_SUBSCRIPTION_POLICY");
        vm.stopBroadcast();

        _checkExpectedAddress(policy, "SALT_SUBSCRIPTION_POLICY");
        _logAddress("SUBSCRIPTION_POLICY", policy);
        return policy;
    }
}
