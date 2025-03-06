// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title ICampaign
/// @notice Interface for managing campaigns, providing functionality for execution and retrieving campaign terms.
/// @dev Defines the required functions for implementing campaign operations.
interface ICampaign {
    /// @notice Executes a campaign run for the specified account.
    /// @dev This function triggers the core campaign logic, such as allocating funds or tracking access.
    /// Implementations may enforce additional restrictions based on campaign rules.
    /// @param account The address of the user or recipient receiving sponsored access during the campaign run.
    /// @return allocatedAmount The amount of funds allocated for the campaign run.
    function run(address account) external returns (uint256 allocatedAmount);

    /// @notice Determines if the campaign is active or eligible for a given operator and account.
    /// @param operator The operator controlling the campaign.
    /// @param account The account to check usage state.
    function isActive(address operator, address account) external view returns (bool isActiveStatus);
}
