// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ICampaign
/// @notice Interface for campaign management, allowing execution of campaign operations.
/// @dev Defines the external function required for campaign execution.
interface ICampaign {
    /// @notice Executes a campaign run for the specified account.
    /// @param sponsor The address of the campaign owner.
    /// @param account The address of the sponsored access.
    /// @return The amount of funds allocated for the campaign run.
    function run(address sponsor, address account) external returns (uint256);
}
