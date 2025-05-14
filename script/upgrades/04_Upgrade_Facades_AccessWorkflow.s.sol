// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { UpgradeBase } from "script/upgrades/00_Upgrade_Base.s.sol";
import { AccessWorkflow } from "contracts/facades/workflows/AccessWorkflow.sol";

contract DeployAccessAgg is UpgradeBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());
          address mmc = vm.envAddress("MMC");
        address ledgerVault = vm.envAddress("LEDGER_VAULT");
        address agreementManager = vm.envAddress("AGREEMENT_MANAGER");
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");

        address impl = address(new AccessWorkflow(rightsPolicyManager, agreementManager, ledgerVault, mmc));
        address accessWorkflowProxy = vm.envAddress("ACCESS_WORKFLOW");

        // address accessManager = vm.envAddress("ACCESS_MANAGER");
        //!IMPORTANT: This is not a safe upgrade, take any caution or 2-check needed before run this method
        address accessWorkflow = upgradeAndCallUUPS(accessWorkflowProxy, address(impl), ""); // no initialization
        vm.stopBroadcast();
        return accessWorkflow;

    }
}
