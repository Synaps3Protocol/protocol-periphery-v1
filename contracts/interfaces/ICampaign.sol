// SPDX-License-Identifier: MIT
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

    /// @notice Checks whether a given operator is active within the campaign.
    /// @dev This function verifies if the specified address has permissions to operate in the campaign.
    /// @param operator The address of the entity being checked.
    /// @return isActiveStatus A boolean indicating whether the operator is active (`true`) or inactive (`false`).
    function isActive(address operator) external view returns (bool isActiveStatus);
}
