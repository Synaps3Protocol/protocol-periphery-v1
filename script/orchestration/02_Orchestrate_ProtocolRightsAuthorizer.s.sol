// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;
import "forge-std/Script.sol";

import { IPolicy } from "@synaps3/core/interfaces/policies/IPolicy.sol";
import { IRightsPolicyAuthorizer } from "@synaps3/core/interfaces/rights/IRightsPolicyAuthorizer.sol";
import { T } from "@synaps3/core/primitives/Types.sol";

contract OrchestrateRightsAuthorizer is Script {
    function run() external {
        uint256 admin = vm.envUint("PRIVATE_KEY");
        address mmc = vm.envAddress("MMC");
        address rightsAuthorizer = vm.envAddress("RIGHT_POLICY_AUTHORIZER");
        address subscriptionPolicy = vm.envAddress("SUBSCRIPTION_POLICY");

        vm.startBroadcast(admin);
        // approve initial distributor
        IRightsPolicyAuthorizer custodian = IRightsPolicyAuthorizer(rightsAuthorizer);
        custodian.authorizePolicy(subscriptionPolicy, abi.encode(1 * 1e18, mmc)); // set terms to policy
        require(custodian.isPolicyAuthorized(subscriptionPolicy, msg.sender) == true);

        // verify policy initialization
        bytes memory criteria = abi.encode(msg.sender);
        T.Terms memory terms = IPolicy(subscriptionPolicy).resolveTerms(criteria);
        require(terms.amount == 1 * 1e18);
        require(terms.currency == mmc);
        require(terms.timeFrame == T.TimeFrame.DAILY);
        vm.stopBroadcast();
    }
}
