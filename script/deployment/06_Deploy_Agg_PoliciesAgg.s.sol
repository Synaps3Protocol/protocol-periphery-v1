// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { PoliciesAgg } from "contracts/aggregation/PoliciesAgg.sol";

contract DeployPoliciesAgg is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());

        address accessManager = vm.envAddress("ACCESS_MANAGER");
        address assetOwnership = vm.envAddress("ASSET_OWNERSHIP");
        address rightsPolicyAuthorizer = vm.envAddress("RIGHT_POLICY_AUTHORIZER");

        address impl = address(new PoliciesAgg(rightsPolicyAuthorizer, assetOwnership));
        bytes memory init = abi.encodeCall(PoliciesAgg.initialize, (accessManager));
        address policiesAggregator = deployUUPS(impl, init, "SALT_POLICIES_AGG");
        vm.stopBroadcast();

        _checkExpectedAddress(policiesAggregator, "SALT_POLICIES_AGG");
        _logAddress("POLICIES_AGG", policiesAggregator);
        return policiesAggregator;
    }
}
