// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { CampaignSubscriptionTpl } from "contracts/incentives/campaigns/sponsored/CampaignSubscriptionTpl.sol";

contract DeployCampaignSubscriptionTpl is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());
        address mmc = vm.envAddress("MMC");
        address ledgerVault = vm.envAddress("LEDGER_VAULT");
        address assetOwnership = vm.envAddress("ASSET_OWNERSHIP");

        bytes memory creationCode = type(CampaignSubscriptionTpl).creationCode;
        bytes memory constructorArgs = abi.encode(ledgerVault, assetOwnership, mmc);
        bytes memory initCode = abi.encodePacked(creationCode, constructorArgs);
        address subscriptionCampaign = deploy(initCode, "SALT_CAMPAIGN_SUBSCRIPTION_TPL");
        vm.stopBroadcast();

        _checkExpectedAddress(subscriptionCampaign, "SALT_CAMPAIGN_SUBSCRIPTION_TPL");
        _logAddress("CAMPAIGN_SUBSCRIPTION_TPL", subscriptionCampaign);
        return subscriptionCampaign;
    }
}
