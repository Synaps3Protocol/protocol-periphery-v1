// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { IAssetOwnership } from "@synaps3/core/interfaces/assets/IAssetOwnership.sol";
import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";
import { IRightsPolicyAuthorizer } from "@synaps3/core/interfaces/rights/IRightsPolicyAuthorizer.sol";

import { IPolicy } from "@synaps3/core/interfaces/policies/IPolicy.sol";
import { LoopOps } from "@synaps3/core/libraries/LoopOps.sol";
import { T } from "@synaps3/core/primitives/Types.sol";

contract PoliciesAgg is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    using LoopOps for uint256;

    /// @notice structure to hold the relationship between policy and terms
    struct PolicyTerms {
        address policy;
        T.Terms terms;
    }

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsPolicyAuthorizer public immutable RIGHTS_POLICY_AUTHORIZER;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IAssetOwnership public immutable ASSET_OWNERSHIP;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address rightsPolicyAuthorizer, address assetOwnership) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
        RIGHTS_POLICY_AUTHORIZER = IRightsPolicyAuthorizer(rightsPolicyAuthorizer);
        ASSET_OWNERSHIP = IAssetOwnership(assetOwnership);
    }

    /// @notice Initializes the proxy state.
    /// @dev Sets up the contract for usage.
    /// @param accessManager Address of the Access Manager contract used for permission handling.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Retrieves all policies that apply to the entirety of a holder's content.
    /// @param holder The address of the rights holder whose policies are being queried.
    function getHolderWidePolicies(address holder) external view returns (PolicyTerms[] memory) {
        bytes memory criteria = abi.encode(holder);
        PolicyTerms[] memory policies = getAvailablePoliciesTerms(holder, criteria);
        return policies;
    }

    /// @notice Retrieves all policies that govern operations on a specific asset.
    /// @param assetId The unique identifier of the asset whose policies are being queried.
    function getAssetSpecificPolicies(uint256 assetId) external view returns (PolicyTerms[] memory) {
        bytes memory criteria = abi.encode(assetId);
        address holder = ASSET_OWNERSHIP.ownerOf(assetId);
        PolicyTerms[] memory policies = getAvailablePoliciesTerms(holder, criteria);
        return policies;
    }

    /// @notice Retrieves all available policies for a holder matching specific criteria.
    /// @param holder Address of the rights holder.
    /// @param criteria Encoded data for policy evaluation.
    function getAvailablePoliciesTerms(
        address holder,
        bytes memory criteria
    ) public view returns (PolicyTerms[] memory) {
        address[] memory policies = RIGHTS_POLICY_AUTHORIZER.getAuthorizedPolicies(holder);
        PolicyTerms[] memory terms = new PolicyTerms[](policies.length);
        uint256 availablePoliciesLen = policies.length;

        for (uint256 i = 0; i < availablePoliciesLen; i = i.uncheckedInc()) {
            address policyAddress = policies[i];
            bytes memory callData = abi.encodeCall(IPolicy.resolveTerms, (criteria));
            (bool success, bytes memory result) = policyAddress.staticcall(callData);
            if (!success) continue; // silent failure

            T.Terms memory term = abi.decode(result, (T.Terms));
            terms[i] = PolicyTerms({ policy: policyAddress, terms: term });
        }

        return terms;
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
