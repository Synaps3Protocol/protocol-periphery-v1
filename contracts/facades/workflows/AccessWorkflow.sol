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

    /// @notice Registers a new access agreement in a single transaction.
    /// @dev This function combines multiple steps into a streamlined workflow:
    ///      1. Reserves the specified amount of MMC tokens from the sender.
    ///      2. Creates an agreement using the reserved tokens.
    ///      3. Registers the associated access policy under the agreement.
    /// @param amount The number of MMC tokens to reserve for the agreement.
    /// @param holder The address of the rights holder for the associated assets.
    /// @param policy The address of the policy contract governing the agreement.
    /// @param parties An array of addresses representing the participants involved in the agreement.
    /// @param payload Additional data required to create the agreement.
    /// @return An array of license IDs registered under the agreement.
    function registerAccessAgreement(
        uint256 amount,
        address holder,
        address policy,
        address[] calldata parties,
        bytes calldata payload
    ) public returns (uint256[] memory) {
        require(amount > 0, "Amount cannot be zero");
        require(policy != address(0), "Policy address cannot be zero");
        require(parties.length > 0, "Parties cannot be empty");

        address broker = address(RIGHTS_POLICY_MANAGER);
        // 1- collect reserved fund and make them available for the contract
        // 2- create immediately the agreement with the funds reserved
        // 3- register the policy using the agreement proof
        uint256 confirmed = LEDGER_VAULT.collect(msg.sender, amount, MMC);
        uint256 proof = AGREEMENT_MANAGER.createAgreement(confirmed, MMC, broker, parties, payload);
        uint256[] memory attestations = RIGHTS_POLICY_MANAGER.registerPolicy(proof, holder, policy);
        emit AccessAgreementCreated(holder, policy, proof);
        return attestations;
    }

    //// @notice Handles sponsored access based on campaigns.
    /// @dev This function executes the following steps:
    ///      1. Runs the specified campaign to determine the funds available for sponsorship.
    ///      2. Collects the reserved funds and makes them available for agreement registration.
    ///      3. Registers the sponsored access agreement using the collected funds.
    /// @param holder The address sponsoring the access agreement.
    /// @param campaign The address of the campaign contract.
    /// @param policy The address of the policy contract applied to the sponsored access.
    /// @param parties An array of addresses representing the participants in the sponsored agreement.
    /// @param payload Additional data required for the agreement registration.
    /// @return An array of IDs representing the licenses registered for the sponsored agreement.
    function sponsoredAccessAgreement(
        address holder,
        address campaign, // eg. campaign registry
        address policy, // eg. subscription
        address[] calldata parties,
        bytes calldata payload
    ) public returns (uint256[] memory) {
        require(policy != address(0), "Policy address cannot be zero");
        require(campaign != address(0), "Campaign address cannot be zero");
        // run the campaign to get the funds for the registration
        ICampaign campaign_ = ICampaign(campaign);
        uint256 reserved = campaign_.run(msg.sender);

        // reserve funds to workflow and register agreement
        uint256 confirmed = LEDGER_VAULT.collect(campaign, reserved, MMC);
        emit SponsoredAccess(campaign, holder, policy, confirmed, parties);
        return registerAccessAgreement(reserved, holder, policy, parties, payload);
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
