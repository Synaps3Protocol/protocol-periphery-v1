// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { SubscriptionCampaign } from "contracts/incentives/campaigns/SubscriptionCampaign.sol";

contract DeploySubscriptionCampaign is DeployBase {
    function run() external returns (address subscriptionCampaign) {
        vm.startBroadcast(getAdminPK());
        address mmc = vm.envAddress("MMC");
        address ledgerVault = vm.envAddress("LEDGER_VAULT");
        address accessManager = vm.envAddress("ACCESS_MANAGER");
        address subscriptionAddress = vm.envAddress("SUBSCRIPTION_POLICY");

        address impl = address(new SubscriptionCampaign(ledgerVault, subscriptionAddress, mmc));
        bytes memory init = abi.encodeCall(SubscriptionCampaign.initialize, (accessManager));
        subscriptionCampaign = deployUUPS(impl, init, "SALT_SUBSCRIPTION_CAMPAIGN");
        vm.stopBroadcast();

        _checkExpectedAddress(subscriptionCampaign, "SALT_SUBSCRIPTION_CAMPAIGN");
        _logAddress("SUBSCRIPTION_CAMPAIGN", subscriptionCampaign);
    }
}
