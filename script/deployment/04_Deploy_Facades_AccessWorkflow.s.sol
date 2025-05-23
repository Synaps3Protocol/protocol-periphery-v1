// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { AccessWorkflow } from "contracts/facades/workflows/AccessWorkflow.sol";

contract DeployAccessWorkflow is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());
        address mmc = vm.envAddress("MMC");
        address accessManager = vm.envAddress("ACCESS_MANAGER");
        address ledgerVault = vm.envAddress("LEDGER_VAULT");
        address agreementManager = vm.envAddress("AGREEMENT_MANAGER");
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");

        address impl = address(new AccessWorkflow(rightsPolicyManager, agreementManager, ledgerVault, mmc));
        bytes memory init = abi.encodeCall(AccessWorkflow.initialize, (accessManager));
        address accessWorkflow = deployUUPS(impl, init, "SALT_ACCESS_WORKFLOW");
        vm.stopBroadcast();

        _checkExpectedAddress(accessWorkflow, "SALT_ACCESS_WORKFLOW");
        _logAddress("ACCESS_WORKFLOW", accessWorkflow);
        return accessWorkflow;
    }
}
