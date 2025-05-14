// SPDX-License-Identifier: BUSL-1.1
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
    /// @param account The account registering access agreement.
    /// @param holder The address of the holder sponsoring the access.
    /// @param policy The policy address being sponsored.
    event AccessAgreementCreated(address indexed account, address indexed holder, address indexed policy);
    /// @notice Emitted when a sponsored access is registered.
    /// @param campaign The sponsor campaign address.
    /// @param holder The address of the holder sponsoring the access.
    /// @param policy The policy address being sponsored.
    event SponsoredAccessCreated(address indexed campaign, address indexed holder, address indexed policy);

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
    function registerAccessAgreement(
        uint256 amount,
        address holder,
        address policy,
        address[] calldata parties,
        bytes calldata payload
    ) external {
        require(amount > 0, "Amount cannot be zero");
        require(policy != address(0), "Policy address cannot be zero");
        require(parties.length > 0, "Parties cannot be empty");

        // Step 1: Collect and reserve MMC tokens from the sender.
        // Step 2: Create the agreement immediately using the reserved tokens.
        // Step 3: Register the policy using the generated agreement proof.
        _registerAccessAgreement(amount, msg.sender, holder, policy, parties, payload);
        emit AccessAgreementCreated(msg.sender, holder, policy);
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
    function sponsoredAccessAgreement(
        address holder,
        address campaign, // eg. campaign registry
        address policy, // eg. subscription
        address[] calldata parties,
        bytes calldata payload
    ) external {
        require(policy != address(0), "Policy address cannot be zero");
        require(campaign != address(0), "Campaign address cannot be zero");
        // Step 1: Run the campaign contract to determine available sponsorship funds.
        // Step 2: Reserve the collected funds and register the sponsored agreement.
        uint256 sponsoredAmount = ICampaign(campaign).run(msg.sender);
        _registerAccessAgreement(sponsoredAmount, campaign, holder, policy, parties, payload);
        emit SponsoredAccessCreated(campaign, holder, policy);
    }

    /// @dev Internal function to register an access agreement.
    /// @param amount Amount of MMC tokens reserved for the agreement.
    /// @param initiator Address that initiates the agreement registration.
    /// @param holder Rights holder who will have access.
    /// @param policy Policy contract that governs access rules.
    /// @param parties List of participants involved in the agreement.
    /// @param payload Additional metadata required to create the agreement.
    function _registerAccessAgreement(
        uint256 amount,
        address initiator,
        address holder,
        address policy,
        address[] calldata parties,
        bytes calldata payload
    ) private returns (uint256[] memory) {
        address broker = address(RIGHTS_POLICY_MANAGER);
        uint256 confirmed = LEDGER_VAULT.collect(initiator, amount, MMC);
        uint256 proof = AGREEMENT_MANAGER.createAgreement(confirmed, MMC, broker, parties, payload);
        return RIGHTS_POLICY_MANAGER.registerPolicy(proof, holder, policy);
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
