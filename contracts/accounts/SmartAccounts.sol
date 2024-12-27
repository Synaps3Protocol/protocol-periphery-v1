// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC4337 } from "solady/accounts/ERC4337.sol";

/// @title SmartAccounts
/// @dev This contract extends the ERC4337 implementation to provide specific behavior for
///      signature verification and domain information for EIP-712 compatibility.
/// https://eips.ethereum.org/EIPS/eip-4337
contract SmartAccounts is ERC4337 {
    /// @notice Returns the address used to verify ERC1271 signatures.
    /// @dev Overrides the `_erc1271Signer` function from the ERC1271 contract.
    ///      This implementation uses the owner of the account as the signer.
    /// @return The address of the signer, which is the owner of the account.
    function _erc1271Signer() internal view override returns (address) {
        return owner(); // Uses the `owner` function from the `Ownable` contract.
    }

    /// @notice Provides the domain name and version for EIP-712 typed data signing.
    /// @dev Overrides the `_domainNameAndVersion` function from the ERC4337 contract.
    ///      This is used in EIP-712 for encoding domain-separated data.
    /// @return name The name of the domain.
    /// @return version The version of the domain.
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        return ("SmartAccount", "1"); // Provides a domain name and version specific to this contract.
    }
}
