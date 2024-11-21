// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { AgreementPortal } from "contracts/agreements/AgreementPortal.sol";

contract DeployAgreementPortal is DeployBase {
    function run() external returns (address agreementPortal) {
        vm.startBroadcast(getAdminPK());
        address mmc = vm.envAddress("MMC");
        address accessManager = vm.envAddress("ACCESS_MANAGER");
        address rightsAgreement = vm.envAddress("RIGHT_ACCESS_AGREEMENT");
        address rightsPolicyManager = vm.envAddress("RIGHT_POLICY_MANAGER");

        address impl = address(new AgreementPortal(rightsPolicyManager, rightsAgreement, mmc));
        bytes memory init = abi.encodeCall(AgreementPortal.initialize, (accessManager));
        agreementPortal = deployUUPS(impl, init, "SALT_AGREEMENT_PORTAL");
        vm.stopBroadcast();

        _checkExpectedAddress(agreementPortal, "SALT_AGREEMENT_PORTAL");
        _logAddress("AGREEMENT_PORTAL", agreementPortal);
    }
}
