// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";
import { PolicyOps } from "contracts/libraries/PolicyOps.sol";
import { PolicyBase } from "@synaps3/policies/PolicyBase.sol";
import { LoopOps } from "@synaps3/core/libraries/LoopOps.sol";
import { T } from "@synaps3/core/primitives/Types.sol";

/// @title SubscriptionPolicy
/// @notice Implements a subscription-based content access policy.
contract SubscriptionPolicy is Initializable, PolicyBase, UUPSUpgradeable, AccessControlledUpgradeable {
    using LoopOps for uint256;
    using PolicyOps for uint256;

    /// @dev Structure to define a subscription package.
    struct Package {
        uint256 pricePerDay;
        address currency;
    }

    // Mapping from content holder (address) to their subscription package details.
    mapping(address => Package) private _packages;

    /// @notice Emitted when a subscription is enforced.
    /// @param holder The address of the rights holder associated with the subscription.
    /// @param pricePerDay The daily price of the subscription.
    /// @param duration The calculated subscription duration in days.
    event SubscriptionEnforced(address indexed holder, uint256 pricePerDay, uint256 duration);

    constructor(
        address rightPolicyManager,
        address rightsAuthorizer,
        address assetOwnership,
        address attestationProvider
    ) PolicyBase(rightPolicyManager, rightsAuthorizer, assetOwnership, attestationProvider) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
    }

    /// @notice Initializes the proxy state.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Returns the name of the policy.
    function name() external pure returns (string memory) {
        return "SubscriptionPolicy";
    }

    /// @notice Returns the business/strategy model implemented by the policy.
    function description() external pure returns (string memory) {
        return
            "This policy follows a subscription model with daily pricing, allowing users to access "
            "a content holder's catalog by paying a daily fee for a chosen duration.\n\n"
            "Key features:\n"
            "1) Flexible subscription periods set by the asset holder.\n"
            "2) Instant access to all content during the subscription period.";
    }

    // TODOpotential improvement to scaling custom actions in protocol using hooks
    // eg: access handling for gating content. etc.. dynamic prices: discounts, etc IPricesHook
    // function isAccessAllowed(bytes calldata criteria) external view return (bool) {
    //  // get registered access hooks for this contract
    //  IHook hook = HOOKS.get(address(this), IAccessHook) <- logic needed to get the valid hook
    //  if (!hook) return false // need conf hook
    //  return hook.exec(criteria)
    //}

    function setup(address holder, bytes calldata init) external onlyPolicyAuthorizer activate {
        (uint256 price, address currency) = abi.decode(init, (uint256, address));
        if (price == 0) revert InvalidSetup("Invalid subscription price.");
        // expected content subscription params..
        _packages[holder] = Package(price, currency);
    }

    // this function should be called only by RM and its used to establish
    // any logic or validation needed to set the authorization parameters
    function enforce(
        address holder,
        T.Agreement calldata agreement
    ) external onlyPolicyManager active returns (uint256[] memory) {
        Package memory pkg = _packages[holder];
        uint256 duration = _calcExpectedDuration(pkg, agreement);
        uint256 subExpire = _calculateSubscriptionExpiration(duration);
        uint256[] memory attestationIds = _commit(holder, agreement, subExpire);

        _updateBatchAttestation(holder, attestationIds, agreement.parties);
        emit SubscriptionEnforced(holder, pkg.pricePerDay, duration);
        return attestationIds;
    }

    /// @notice Verifies if an account has access to holder's content or asset id.
    function isAccessAllowed(address account, bytes calldata criteria) external view returns (bool) {
        // Default behavior: only check attestation compliance for holder account.
        address holder = _decodeCriteria(criteria);
        // a clear use case is check against the policy about the access to an asset id
        // validate access on asset id criteria on the subgroup of holder's content.
        return _isCompliant(account, holder);
    }

    /// @notice Retrieves the terms associated with a specific criteria and policy.
    function resolveTerms(bytes calldata criteria) external view returns (T.Terms memory) {
        address holder = _decodeCriteria(criteria);
        Package memory pkg = _packages[holder]; // the term set by the asset holder
        return T.Terms(pkg.pricePerDay, pkg.currency, T.TimeFrame.DAILY, "ipfs://");
    }

    /// @dev Authorizes the upgrade of the contract.
    /// @notice Only the owner can authorize the upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /// @notice Updates the attestation records for each account.
    /// @param attestationIds The ID of the attestations.
    /// @param parties The list of account to assign attestation id.
    function _updateBatchAttestation(
        address holder,
        uint256[] memory attestationIds,
        address[] memory parties
    ) private {
        uint256 partiesLen = parties.length;
        for (uint256 i = 0; i < partiesLen; i = i.uncheckedInc()) {
            bytes memory context = abi.encode(holder); // the license context
            _setAttestation(parties[i], context, attestationIds[i]);
        }
    }

    /// @notice Decodes the criteria to extract the holder's address or resolve it from an asset ID.
    /// @dev Checks if the criteria is an address; otherwise, assumes it's an asset ID and resolves the holder.
    function _decodeCriteria(bytes calldata criteria) private view returns (address) {
        // we expect always two inputs eg: address or uint256
        // if the criteria is an address we assume the holder address else an assetId
        if (criteria.length != 32) revert InvalidNotSupportedOperation();
        if (_isHolderAddress(criteria)) return abi.decode(criteria, (address));
        uint256 assetId = abi.decode(criteria, (uint256));
        return _getHolder(assetId);
    }

    /// @notice Verifies whether the on-chain access terms are satisfied for an account.
    /// @dev The function checks if the provided account complies with the attestation.
    /// @param account The address of the user whose access is being verified.
    function _isCompliant(address account, address holder) private view returns (bool) {
        bytes memory criteria = abi.encode(holder);
        uint256 attestationId = getLicense(account, criteria);
        // default uint256 attestation is zero <- means not registered
        if (attestationId == 0) return false; // false if not registered
        return ATTESTATION_PROVIDER.verify(attestationId, account);
    }

    /// @notice Detects whether the criteria represents a holder's address or an asset ID.
    /// @dev Determines if the input bytes represent a 20-byte address by checking leading/trailing zeros.
    function _isHolderAddress(bytes calldata criteria) private pure returns (bool) {
        // Detecting the "address shape" for the argument to handle polymorphic validation.
        // If the second argument has the structure of an address (20 bytes with 12 leading zero bytes),
        // it is treated as a `holder`. Otherwise, it is treated as an `assetId`.
        // The likelihood of a mismatch in this validation is low, as `assetId` is expected to be a long integer.
        // https://github.com/ethereum/solidity-examples/blob/master/docs/bytes/Bytes.md
        // TODO: potential improvement:
        // https://github.com/ethereum/solidity/issues/10381
        // https://forum.soliditylang.org/t/call-for-feedback-the-future-of-try-catch-in-solidity/1497
        bool last20Valid = bytes20(criteria[12:32]) != bytes20(0);
        bool first12Valid = bytes12(criteria[0:12]) == bytes12(0);
        return last20Valid && first12Valid;
    }

    /// @notice Calculates the expected duration of a subscription based on the payment amount.
    /// @dev Ensures the subscriber has paid enough for the required duration and number of parties.
    /// @param package The subscription package of the holder.
    /// @param agreement The agreement details.
    function _calcExpectedDuration(
        Package memory package,
        T.Agreement calldata agreement
    ) private pure returns (uint256) {
        uint256 paidAmount = agreement.total;
        uint256 partiesLen = agreement.parties.length;
        uint256 pricePerDay = package.pricePerDay;

        (uint256 duration, uint256 totalToPay) = paidAmount.calcDuration(pricePerDay, partiesLen);
        if (paidAmount < totalToPay) revert InvalidEnforcement("Insufficient funds for subscription");
        return duration;
    }

    /// @notice Calculates the expiration timestamp for the subscription.
    /// @param duration The duration in days.
    /// @return subExpire The calculated expiration timestamp.
    function _calculateSubscriptionExpiration(uint256 duration) private view returns (uint256 subExpire) {
        return block.timestamp + (duration * 1 days);
    }
}
