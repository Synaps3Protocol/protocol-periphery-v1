// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { AccessControlledUpgradeable } from "@synaps3/primitives/upgradeable/AccessControlledUpgradeable.sol";
import { IRightsPolicyManager } from "@synaps3/interfaces/rights/IRightsPolicyManager.sol";
import { IRightsAccessAgreement } from "@synaps3/interfaces/rights/IRightsAccessAgreement.sol";

contract AgreementPortal is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsPolicyManager public immutable RIGHTS_POLICY_MANAGER;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsAccessAgreement public immutable RIGHTS_AGREEMENT;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address rightsPolicyManager, address rightsAgreement) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
        RIGHTS_POLICY_MANAGER = IRightsPolicyManager(rightsPolicyManager);
        RIGHTS_AGREEMENT = IRightsAccessAgreement(rightsAgreement);
    }

    /// @notice Initializes the proxy state.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    function flashAgreement(
        uint256 amount,
        address holder,
        address currency,
        address policyAddress,
        address[] calldata parties,
        bytes calldata payload
    ) public returns (uint256) {
        address broker = address(RIGHTS_POLICY_MANAGER);
        uint256 proof = RIGHTS_AGREEMENT.createAgreement(amount, currency, broker, parties, payload);
        return RIGHTS_POLICY_MANAGER.registerPolicy(proof, holder, policyAddress);
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
