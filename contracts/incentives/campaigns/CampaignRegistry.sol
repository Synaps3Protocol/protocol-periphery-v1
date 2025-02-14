// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";
import { ICampaign } from "contracts/interfaces/ICampaign.sol";

/// @title CampaignRegistry
/// @notice Manages campaign contract registrations, allowing users to deploy and track campaigns.
/// @dev Supports upgradeability via UUPS and integrates with an access control system.
///      Uses ERC165 to verify that contracts implement the required campaign interface.
contract CampaignRegistry is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    using Clones for address;
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant MIN_EXPIRE_AT = 1 hours;
    /// @dev The interface ID for ICampaign, used to verify that a campaign contract implements the correct interface.
    bytes4 private constant INTERFACE_CAMPAIGN = type(ICampaign).interfaceId;
    /// @dev Maps a campaign reference to its associated scope, which defines the entity the campaign operates on.
    mapping(bytes32 => address) private _scopes;

    /// @notice Event emitted when a new campaign is registered.
    event CampaignRegistered(
        address indexed owner,
        address indexed campaign,
        uint256 indexed expireAt,
        bytes32 scopeId,
        string description
    );

    /// @notice Custom error for invalid campaign contracts.
    error InvalidCampaignContract(address campaign);
    /// @notice Custom error when a campaign setup fails.
    error ErrorDuringCampaignSetup(address campaign);
    /// @notice Custom error when an unauthorized action is attempted.
    error Unauthorized();
    /// @notice Custom error when invalid input is provided.
    error InvalidInput();

    /// @dev Modifier to ensure only valid campaign contracts can be registered.
    modifier onlyValidCampaigns(address campaign) {
        if (!campaign.supportsInterface(INTERFACE_CAMPAIGN)) {
            revert InvalidCampaignContract(campaign);
        }
        _;
    }

    /// @notice Initializes the contract with access control.
    /// @dev Sets up initial roles and dependencies for upgradeability and access management.
    /// @param accessManager The address of the access control manager contract.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Retrieves the campaign associated with a given account and policy.
    /// @dev Computes a unique identifier (`scopeId`) based on the account and policy address.
    ///      If a campaign is registered under this identifier, it returns the campaign address;
    ///      otherwise, it returns `address(0)`.
    /// @param account The address of the account (holder) making the query.
    /// @param policy The address of the policy contract associated with the campaign.
    /// @return The address of the associated campaign if found, otherwise `address(0)`.
    function getCampaign(address account, address policy) external view returns (address) {
        // Compute the unique identifier for the campaign association
        return _scopes[_computeComposedKey(account, policy)];
    }

    /// @notice Creates and registers a new campaign by cloning a given template contract.
    /// @dev The provided template must be a valid campaign contract.
    /// @param template The address of the campaign contract to clone.
    /// @param policy The policy the campaign is linked to.
    /// @param expiration The timestamp when the campaign expires.
    /// @param description A brief description of the campaign.
    /// @return The address of the newly created campaign.
    function createCampaign(
        address template,
        address policy,
        uint256 expiration,
        string calldata description
    ) external onlyValidCampaigns(template) returns (address) {
        // minimum 1 hour to set as expire at
        if (expiration < MIN_EXPIRE_AT) {
            revert InvalidInput();
        }

        uint expireAt = block.timestamp + expiration;
        address clone = _clone(template, expireAt);
        address campaign = _setup(clone, expireAt);
        // store "linked" owner + scope + campaign
        // this is useful during campaign retrieval from scope context
        bytes32 scopeId = _addScopeAssoc(msg.sender, policy, campaign);
        emit CampaignRegistered(msg.sender, campaign, expireAt, scopeId, description);
        return campaign;
    }

    /// @notice Authorizes upgrades to the contract.
    /// @dev Ensures that only an admin can perform upgrades.
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /// @dev Internal function to initialize a cloned campaign.
    /// @param campaign The address of the newly cloned campaign.
    /// @param expireAt The timestamp when the campaign expires.
    /// @return The initialized campaign address.
    function _setup(address campaign, uint256 expireAt) private returns (address) {
        bytes memory callData = abi.encodeWithSignature("initialize(address,uint256)", msg.sender, expireAt);
        (bool success, ) = campaign.call(callData);
        if (!success) revert ErrorDuringCampaignSetup(campaign);
        return campaign;
    }

    /// @dev Creates a unique identifier for the scope based on the owner's address
    ///      and the scope address. The generated scope ID is mapped to the campaign
    ///      in the `_scopes` mapping, allowing efficient retrieval.
    /// @param owner The address of the owner managing the scope.
    /// @param policy The address representing the policy.
    /// @param campaign The address of the associated campaign.
    /// @return scopeId The unique identifier for the scope association.
    function _addScopeAssoc(address owner, address policy, address campaign) private returns (bytes32) {
        bytes32 scopeId = _computeComposedKey(owner, policy);
        _scopes[scopeId] = campaign; // associate the scope ID with the campaign
        return scopeId;
    }

    /// @dev Deploy a new minimal-proxy (EIP-1167) based on the specified campaign template.
    function _clone(address template, uint256 expireAt) private returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, template, expireAt));
        return template.cloneDeterministic(salt);
    }

    /// @notice Computes a unique key by combining a scope and an account address.
    /// @param account The address of the user for whom the key is being generated.
    /// @param scope The address representing the scope.
    /// @return A `bytes32` hash that uniquely identifies the context-account pair.
    function _computeComposedKey(address account, address scope) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, scope));
    }
}
