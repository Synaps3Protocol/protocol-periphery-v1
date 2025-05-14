// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { CampaignBase } from "contracts/incentives/campaigns/CampaignBase.sol";

// TODO add exclusion or restrictions for specific content
// eg. scope = rental, allow only = content2, content3 and content4

/// @title CampaignSubscription
/// @notice Abstract contract for managing subscription-based campaigns.
contract CampaignSubscriptionTpl is CampaignBase {
    /// @notice Initializes the contract by passing dependencies to `CampaignBase`.
    /// @dev This constructor is called when deploying a contract that extends `SubscriptionCampaign`.
    /// @param ledgerVault The address of the ledger vault contract handling fund operations.
    /// @param assetOwnership The address managing asset ownership verification.
    /// @param mmc The address of the MMC token used for campaign-related transactions.
    constructor(
        address ledgerVault,
        address assetOwnership,
        address mmc
    ) CampaignBase(ledgerVault, assetOwnership, mmc) {}
}
