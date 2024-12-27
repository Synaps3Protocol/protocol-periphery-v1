// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";
import { IRightsPolicyManager } from "@synaps3/core/interfaces/rights/IRightsPolicyManager.sol";

contract AccessAgg is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsPolicyManager public immutable RIGHTS_POLICY_MANAGER;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address rightsPolicyManager) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
        RIGHTS_POLICY_MANAGER = IRightsPolicyManager(rightsPolicyManager);
    }

    /// @notice Initializes the proxy state.
    /// @dev Sets up the contract for usage.
    /// @param accessManager Address of the Access Manager contract used for permission handling.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Checks if an account has access rights based on a holder's criteria.
    /// @param account Address of the account to verify.
    /// @param holder Address of the rights holder used as criteria.
    /// @return active True if the account has access; otherwise, false.
    function isAccessAllowedByHolder(address account, address holder) external view returns (bool) {
        bytes memory criteria = abi.encode(holder);
        (bool active, ) = RIGHTS_POLICY_MANAGER.getActivePolicy(account, criteria);
        return active;
    }

    /// @notice Checks if an account has access to a specific asset ID.
    /// @param account Address of the account to verify.
    /// @param assetId ID of the asset used as criteria.
    /// @return active True if the account has access; otherwise, false.
    function isAccessAllowedByAsset(address account, uint256 assetId) external view returns (bool) {
        bytes memory criteria = abi.encode(assetId);
        (bool active, ) = RIGHTS_POLICY_MANAGER.getActivePolicy(account, criteria);
        return active;
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
