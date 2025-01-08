// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { FinancialOps } from "@synaps3/core/libraries/FinancialOps.sol";
import { BaseWorkflow } from "contracts/facades/BaseWorkflow.sol";
import { ICampaign } from "contracts/interfaces/ICampaign.sol";

/// @title AccessWorkflow
/// @notice Handles comprehensive workflows for access management, agreement creation, policy registration.
/// @dev This contract provides a unified interface to interact with access and policy management.
contract AccessWorkflow is BaseWorkflow {
    using FinancialOps for address;

    /// @notice Emitted when a policy agreement workflow is successfully completed.
    /// @param holder The address of the rights holder.
    /// @param policyAddress The address of the registered policy.
    /// @param proof The unique identifier of the agreement.
    event AccessAgreementCreated(address indexed holder, address indexed policyAddress, uint256 proof);

    /// @notice Emitted when a sponsored access is registered.
    /// @param campaign The campaign identifier.
    /// @param holder The address of the holder sponsoring the access.
    /// @param policyAddress The policy address being sponsored.
    /// @param reservedAmount The amount of funds reserved for the access.
    /// @param parties The list of parties involved in the access.
    event SponsoredAccess(
        address indexed campaign,
        address indexed holder,
        address indexed policyAddress,
        uint256 reservedAmount,
        address[] parties
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address rightsPolicyManager,
        address agreementManager,
        address ledgerVault,
        address mmc
    ) BaseWorkflow(rightsPolicyManager, agreementManager, ledgerVault, mmc) {}

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
    /// @return An array of registered licenses under the agreement.
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

        address broker = address(RIGHTS_POLICY_MANAGER);
        // 1- collect reserved fund and make them available for the contract
        // 2- create immediately the agreement with the funds reserved
        // 3- register the policy using the agreement proof
        uint256 confirmed = LEDGER_VAULT.collect(msg.sender, amount, MMC);
        uint256 proof = AGREEMENT_MANAGER.createAgreement(confirmed, MMC, broker, parties, payload);
        uint256[] memory attestations = RIGHTS_POLICY_MANAGER.registerPolicy(proof, holder, policyAddress);
        emit AccessAgreementCreated(holder, policyAddress, proof);
        return attestations;
    }

    /// @notice Handles the process of sponsored access for a campaign.
    /// @dev This function facilitates the execution of a campaign,
    ///      collection of funds, and registration of access agreements.
    /// @param holder The address of the account sponsoring the access.
    /// @param campaignAddress The address of the campaign contract managing the sponsorship.
    /// @param policyAddress The address of the policy being enforced for the sponsored access.
    /// @param parties The list of parties involved in the sponsored access agreement.
    /// @param payload Additional data relevant to the access agreement registration.
    /// @return An array of IDs representing the registered licenses.
    function registerSponsoredAccessAgreement(
        address holder,
        address campaignAddress,
        address policyAddress,
        address[] calldata parties,
        bytes calldata payload
    ) public returns (uint256[] memory) {
        // run the campaign to get the funds for the registration
        ICampaign campaign = ICampaign(campaignAddress);
        uint256 reserved = campaign.run(holder, msg.sender);
        // reserve funds to workflow and register agreement
        uint256 confirmed = LEDGER_VAULT.collect(campaignAddress, reserved, MMC);
        emit SponsoredAccess(campaignAddress, holder, policyAddress, confirmed, parties);
        return registerAccessAgreement(reserved, holder, policyAddress, parties, payload);
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
