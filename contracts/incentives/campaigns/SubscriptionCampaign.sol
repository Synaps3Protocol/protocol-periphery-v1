// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { BaseCampaign } from "contracts/incentives/BaseCampaign.sol";
import { SubscriptionOps } from "contracts/libraries/SubscriptionOps.sol";
import { T } from "@synaps3/core/primitives/Types.sol";

contract SubscriptionCampaign is BaseCampaign {
    using SubscriptionOps for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address ledgerVault, address mmc, address policy) BaseCampaign(ledgerVault, mmc, policy) {}

    /// @notice Initializes the contract state.
    /// @param accessManager The address of the access manager.
    function initialize(address accessManager) public initializer {
        __Ledger_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Retrieves the terms of the campaign for a specific account and broker.
    /// @dev Combines allocation and policy details to calculate the duration and allocation of the campaign.
    ///      Uses `SubscriptionOps` to compute the duration based on the allocated funds and the policy's terms.
    /// @param account The address of the campaign owner or sponsor.
    /// @param broker The address of the broker managing the campaign.
    /// @return A `CampaignTerms` struct containing the calculated duration and the allocated amount.
    function getTerms(address account, address broker) external view returns (CampaignTerms memory) {
        bytes memory holder = abi.encode(account); // Encodes the account address to pass to the policy resolver.
        T.Terms memory terms = POLICY.resolveTerms(holder); // Resolves the policy terms for the account.
        // Retrieves the allocated amount for the specified account and broker.
        uint256 allocatedAmount = _getAllocation(account, broker);
        // Calculates the subscription duration based on the allocated amount and the price per day from the policy.
        (uint256 duration, uint256 total) = allocatedAmount.calcDuration(terms.amount, 1);
        // Returns the campaign terms with the calculated duration and total allocation.
        return CampaignTerms(duration, total);
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
