// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";

import { IRightsPolicyManager } from "@synaps3/core/interfaces/rights/IRightsPolicyManager.sol";
import { IPolicy } from "@synaps3/core/interfaces/policies/IPolicy.sol";
import { LoopOps } from "@synaps3/core/libraries/LoopOps.sol";

/// @title Access Aggregator
/// @notice This contract aggregates access control logic for licenses and policies.
/// @dev Uses UUPS upgradeable proxy pattern and centralized access control.
contract AccessAgg is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    using LoopOps for uint256;

    /// @notice Data structure representing the relationship between a policy and its associated license.
    struct PolicyLicense {
        address policy; // Address of the policy contract
        uint256 license; // License ID corresponding to the policy
    }

    /// @notice Address of the Rights Policy Manager contract.
    /// @dev This variable is immutable and set at deployment time.
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsPolicyManager public immutable RIGHTS_POLICY_MANAGER;

    /// @notice Constructor to initialize the immutable Rights Policy Manager.
    /// @dev Disables initializers to ensure proper proxy usage.
    /// @param rightsPolicyManager Address of the Rights Policy Manager contract.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address rightsPolicyManager) {
        _disableInitializers();
        // right policy manager is in charge of all policies management
        RIGHTS_POLICY_MANAGER = IRightsPolicyManager(rightsPolicyManager);
    }

    /// @notice Initializes the proxy state.
    /// @dev Sets up the contract for usage and ensures AccessManager is properly set.
    /// @param accessManager Address of the Access Manager contract used for permission handling.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Retrieves all active licenses for a given account and asset holder.
    /// @dev Uses the asset holder address as the criteria for license retrieval.
    /// @param account The address of the account to check.
    /// @param holder The address of the rights holder used as the criteria.
    /// @return An array of PolicyLicense structures.
    function getActiveLicenses(address account, address holder) external view returns (PolicyLicense[] memory) {
        bytes memory criteria = abi.encode(holder); // Encode holder address as search criteria
        return getActivePoliciesLicenses(account, criteria);
    }

    /// @notice Retrieves all active licenses for a given account and asset ID.
    /// @dev Uses the asset ID as the criteria for license retrieval.
    /// @param account The address of the account to check.
    /// @param assetId The ID of the asset used as the criteria.
    /// @return An array of PolicyLicense structures.
    function getActiveLicenses(address account, uint256 assetId) external view returns (PolicyLicense[] memory) {
        bytes memory criteria = abi.encode(assetId); // Encode asset ID as search criteria
        return getActivePoliciesLicenses(account, criteria);
    }

    /// @notice Checks if an account has access rights based on a holder's criteria.
    /// @dev Uses the holder address as the search criteria.
    /// @param account The address of the account to verify.
    /// @param holder The address of the rights holder used as criteria.
    /// @return active True if the account has access; otherwise, false.
    /// @return address The address of the active policy.
    function isAccessAllowed(address account, address holder) public view returns (bool, address) {
        bytes memory criteria = abi.encode(holder); // Encode holder address as search criteria
        return RIGHTS_POLICY_MANAGER.getActivePolicy(account, criteria);
    }

    /// @notice Checks if an account has access to a specific asset ID.
    /// @dev Uses the asset ID as the search criteria.
    /// @param account The address of the account to verify.
    /// @param assetId The ID of the asset used as criteria.
    /// @return active True if the account has access; otherwise, false.
    /// @return address The address of the active policy.
    function isAccessAllowed(address account, uint256 assetId) public view returns (bool, address) {
        bytes memory criteria = abi.encode(assetId); // Encode asset ID as search criteria
        return RIGHTS_POLICY_MANAGER.getActivePolicy(account, criteria);
    }

    /// @notice Retrieves active policies and their corresponding licenses for an account.
    /// @param account The address of the account to check.
    /// @param criteria Encoded criteria used to filter active policies. eg: assetId, holder, groups, etc
    function getActivePoliciesLicenses(
        address account,
        bytes memory criteria
    ) public view returns (PolicyLicense[] memory) {
        // only the matched with valid criteria are returned...
        address[] memory policies = RIGHTS_POLICY_MANAGER.getActivePolicies(account, criteria);
        PolicyLicense[] memory licenses = new PolicyLicense[](policies.length);
        uint256 policiesLen = policies.length;
        uint256 j = 0;

        // limited to policies len
        for (uint256 i = 0; i < policiesLen; i = i.uncheckedInc()) {
            bytes memory callData = abi.encodeCall(IPolicy.getLicense, (account, criteria));
            (bool success, bytes memory result) = policies[i].staticcall(callData); //
            if (!success) continue; // silent error

            uint256 licenseId = abi.decode(result, (uint256));
            licenses[j] = PolicyLicense({ policy: policies[i], license: licenseId });
            // limited to policies success 
            j = j.uncheckedInc();
        }

        // truncate the licenses
        assembly {
            mstore(licenses, j)
        }

        return licenses;
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
