// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { SubscriptionPolicy } from "contracts/policies/SubscriptionPolicy.sol";

contract DeploySubscriptionPolicy is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());

        address assetOwnership = vm.envAddress("ASSET_OWNERSHIP");
        address easAddress = computeCreate3Address("SALT_ATTESTATION_EAS");
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");

        bytes memory creationCode = type(SubscriptionPolicy).creationCode;
        bytes memory initCode = abi.encodePacked(
            creationCode,
            abi.encode(rightsPolicyManager, assetOwnership, easAddress)
        );

        address policy = deploy(initCode, "SALT_SUBSCRIPTION_POLICY");
        vm.stopBroadcast();

        _checkExpectedAddress(policy, "SALT_SUBSCRIPTION_POLICY");
        _logAddress("SUBSCRIPTION_POLICY", policy);
        return policy;
    }
}
