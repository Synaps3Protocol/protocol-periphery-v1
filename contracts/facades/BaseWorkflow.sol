// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IRightsPolicyManager } from "@synaps3/core/interfaces/rights/IRightsPolicyManager.sol";
import { IAgreementManager } from "@synaps3/core/interfaces/financial/IAgreementManager.sol";
import { ILedgerVault } from "@synaps3/core/interfaces/financial/ILedgerVault.sol";

abstract contract BaseWorkflow is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    // base contract list needed on all workflows
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable MMC;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsPolicyManager public immutable RIGHTS_POLICY_MANAGER;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ILedgerVault public immutable LEDGER_VAULT;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IAgreementManager public immutable AGREEMENT_MANAGER;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address rightsPolicyManager, address agreementManager, address ledgerVault, address mmc) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
        LEDGER_VAULT = ILedgerVault(ledgerVault);
        RIGHTS_POLICY_MANAGER = IRightsPolicyManager(rightsPolicyManager);
        AGREEMENT_MANAGER = IAgreementManager(agreementManager);
        MMC = mmc;
    }
}
