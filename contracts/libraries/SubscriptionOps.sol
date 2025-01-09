// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SubscriptionOps Library
/// @notice Provides utility functions for subscription-related operations.
/// @dev This library includes methods to calculate subscription duration and total cost based on payment.
library SubscriptionOps {
    /// @notice Calculates the subscription duration and total cost based on the provided payment amount.
    /// @dev Ensures that the payment covers the total cost of the subscription package for all parties.
    /// @param amount The total payment amount provided for the subscription.
    /// @param pricePerDay The cost of the subscription per day for a single account.
    /// @param partiesLen The number of parties sharing the subscription.
    /// @return duration The calculated subscription duration in days.
    /// @return total The total cost required for the subscription.
    function calcDuration(
        uint256 amount,
        uint256 pricePerDay,
        uint256 partiesLen
    ) internal pure returns (uint256, uint256) {
        // Calculate the payment allocated per account
        uint256 paymentPerAccount = amount / partiesLen;
        // Calculate the subscription duration in days for one account
        uint256 duration = paymentPerAccount / pricePerDay;
        // Calculate the total cost for the subscription for all parties
        uint256 total = (duration * pricePerDay) * partiesLen;
        return (duration, total);
    }
}
