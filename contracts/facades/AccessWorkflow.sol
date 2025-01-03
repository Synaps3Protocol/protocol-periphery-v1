// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";

import { IRightsPolicyManager } from "@synaps3/core/interfaces/rights/IRightsPolicyManager.sol";
import { FinancialOps } from "@synaps3/core/libraries/FinancialOps.sol";
import { LoopOps } from "@synaps3/core/libraries/LoopOps.sol";
import { IAgreementManager } from "@synaps3/core/interfaces/financial/IAgreementManager.sol";
import { IPolicy } from "@synaps3/core/interfaces/policies/IPolicy.sol";
import { T } from "@synaps3/core/primitives/Types.sol";

/// @title AccessWorkflow
/// @notice Handles comprehensive workflows for access management, including agreement creation, policy registration, and related operations.
/// @dev This contract provides a unified interface to interact with multiple core protocol components involved in access and policy management.
contract AccessWorkflow is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    using FinancialOps for address;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsPolicyManager public immutable RIGHTS_POLICY_MANAGER;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IAgreementManager public immutable AGREEMENT_MANAGER;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable MMC;

    /// @notice Emitted when a policy agreement workflow is successfully completed.
    /// @param holder The address of the rights holder.
    /// @param policyAddress The address of the registered policy.
    /// @param proof The unique identifier of the agreement.
    /// @param amount The amount of MMC tokens used in the agreement.
    event AccessAgreementCreated(address indexed holder, address indexed policyAddress, uint256 proof, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address rightsPolicyManager, address agreementManager, address mmc) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
        RIGHTS_POLICY_MANAGER = IRightsPolicyManager(rightsPolicyManager);
        AGREEMENT_MANAGER = IAgreementManager(agreementManager);
        MMC = IERC20(mmc);
    }

    /// @notice Initializes the proxy state.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Creates and registers a new access agreement in a single transaction.
    /// @dev Encapsulates agreement creation and access policy registration into one cohesive workflow.
    /// @param amount The amount of MMC tokens to be used in the agreement.
    /// @param holder The address of the rights holder.
    /// @param policyAddress The address of the policy contract being used.
    /// @param parties An array of addresses representing the parties involved in the agreement.
    /// @param payload Additional data required for the agreement creation.
    /// @return attestationIds An array of registered attestations under the agreement.
    function registerAccessAgreement(
        uint256 amount,
        address holder,
        address policyAddress,
        address[] calldata parties,
        bytes calldata payload
    ) public returns (uint256[] memory) {
        require(amount > 0, "Amount cannot be zero");
        require(policyAddress != address(0), "Policy address cannot be zero");
        require(parties.length > 0, "Parties cannot be empty");

        address currency = address(MMC);
        address broker = address(RIGHTS_POLICY_MANAGER);
        // create immediately the agreement and use it to register the policy
        uint256 proof = AGREEMENT_MANAGER.createAgreement(amount, currency, broker, parties, payload);
        uint256[] memory attestations = RIGHTS_POLICY_MANAGER.registerPolicy(proof, holder, policyAddress);
        emit AccessAgreementCreated(holder, policyAddress, proof, amount);
        return attestations;
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
