// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ICampaign
/// @notice Interface for managing campaigns, providing functionality for execution and retrieving campaign terms.
/// @dev Defines the required functions for implementing campaign operations.
interface ICampaign {
    /// @notice Represents the terms of a campaign.
    /// @dev Contains information about the campaign duration and the allocated amount.
    struct CampaignTerms {
        uint256 duration; // The duration of the campaign, typically in days.
        uint256 allocation; // The total amount allocated for the campaign.
    }

    /// @notice Executes a campaign run for the specified sponsor and account.
    /// @dev This function triggers the core campaign logic, such as allocating funds or tracking access.
    /// @param sponsor The address of the campaign owner or sponsor initiating the campaign run.
    /// @param account The address of the user or recipient receiving sponsored access during the campaign run.
    /// @return The amount of funds allocated for the campaign run.
    function run(address sponsor, address account) external returns (uint256);

    /// @notice Retrieves the terms of the campaign for a specific account and broker.
    /// @dev Combines allocation and policy details to calculate the duration and allocation of the campaign.
    /// @param account The address of the campaign owner or sponsor.
    /// @param broker The address of the broker managing the campaign.
    /// @return A `CampaignTerms` struct containing the calculated duration and the allocated amount.
    function getTerms(address account, address broker) external view returns (CampaignTerms memory);
}
