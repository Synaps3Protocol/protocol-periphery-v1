// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { CampaignRegistry } from "contracts/incentives/campaigns/CampaignRegistry.sol";

contract DeployCampaignRegistry is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());

        address accessManager = vm.envAddress("ACCESS_MANAGER");
        address impl = address(new CampaignRegistry());
        bytes memory init = abi.encodeCall(CampaignRegistry.initialize, (accessManager));
        address campaignRegistry = deployUUPS(impl, init, "SALT_CAMPAIGN_REGISTRY");

        // bytes memory callData = abi.encodeWithSignature(
        //     "createCampaign(uint256,address,string)",
        //     3600,
        //     0xD39a612b9dE73600039eC57E383582b36071faB9,
        //     "Hola mundo"
        // );
        // (bool success, bytes memory result) = campaignRegistry.call(callData);
        // if (!success) revert(abi.decode(result, (string)));
        vm.stopBroadcast();

        _checkExpectedAddress(campaignRegistry, "SALT_CAMPAIGN_REGISTRY");
        _logAddress("CAMPAIGN_REGISTRY", campaignRegistry);
        return campaignRegistry;
    }
}
