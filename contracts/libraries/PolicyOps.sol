// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title PolicyOps Library
/// @notice Provides utility functions for access-related operations.
/// @dev This library includes methods to calculate access duration and total cost based on payment.
library PolicyOps {
    /// @notice Calculates the access duration and total cost based on the provided payment amount.
    /// @dev Ensures that the payment covers the total cost of the package for all parties.
    /// @param amount The total payment amount provided for the access.
    /// @param pricePerUnit The cost of the access per unit (e.g., day, frame) for a single account.
    /// @param partiesLen The number of parties sharing the access.
    /// @return duration The calculated access duration in units.
    /// @return total The total cost required for the access.
    function calcDuration(
        uint256 amount,
        uint256 pricePerUnit,
        uint256 partiesLen
    ) internal pure returns (uint256, uint256) {
        // Calculate the payment allocated per account
        uint256 paymentPerAccount = amount / partiesLen;
        // Calculate the access duration in units for one account
        uint256 duration = paymentPerAccount / pricePerUnit;
        // Calculate the total cost for the access for all parties
        uint256 total = (duration * pricePerUnit) * partiesLen;
        return (duration, total);
    }
}
