// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { LedgerUpgradeable } from "@synaps3/core/primitives/upgradeable/LedgerUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import { ILedgerVault } from "@synaps3/core/interfaces/financial/ILedgerVault.sol";
import { IAssetOwnership } from "@synaps3/core/interfaces/assets/IAssetOwnership.sol";
import { ICampaign } from "contracts/interfaces/ICampaign.sol";

/// @title CampaignBase
/// @notice Abstract contract to handle sponsored campaigns including funds allocation and access control.
abstract contract CampaignBase is
    Initializable,
    ERC165,
    LedgerUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ICampaign
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable MMC;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ILedgerVault public immutable LEDGER_VAULT;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IAssetOwnership public immutable ASSET_OWNERSHIP;

    uint256 private _expires; // Expiration timestamp for the campaign.
    uint256 private _rateLimits; // Maximum sponsored accesses allowed.
    mapping(address => uint256) private _allocation; /// Maps an account + operator to the allocated funds.
    mapping(address => uint256) private _rateCounter; // Number of sponsored accesses used.

    /// @notice Emitted when funds are added to a campaign.
    /// @param amount The amount of funds added.
    event FundsAdded(uint256 amount);

    /// @notice Emitted when funds are removed from a campaign.
    /// @param amount The amount of funds removed.
    event FundsRemoved(uint256 amount);

    /// @notice Emitted when the maximum rate limit is set for an account.
    /// @param limit The new maximum rate limit.
    event MaxRateLimitSet(uint256 limit);

    /// @notice Emitted when an account expiration time is set.
    /// @param expiration The new expiration timestamp.
    event ExpirationSet(uint256 expiration);

    /// @notice Emitted when the rate counter is updated for an account.
    /// @param counter The new rate counter value.
    event RateCounterUpdated(uint256 counter);

    /// @notice Emitted when funds are allocated to an operator for a campaign.
    /// @param operator The operator authorized to use the allocated funds.
    /// @param amount The amount of funds allocated.
    event FundsAllocationSet(address indexed operator, uint256 amount);

    /// @notice Emitted when a campaign `run` is executed.
    /// @param account The account receiving sponsored access.
    /// @param amount The amount of funds allocated during the `run`.
    event CampaignRun(address account, uint256 amount);

    /// @notice Thrown when an operation is attempted with an inactive operator.
    /// @param operator The address of the inactive operator.
    error OperatorNotActive(address operator);

    /// @notice Ensures that the given operator is active before executing the function.
    /// @dev This modifier checks if the operator is active using `isActive(operator)`.
    /// If the operator is inactive, it reverts with `OperatorNotActive`.
    /// @param operator The address of the operator to be checked.
    modifier onlyWhenActiveFor(address operator) {
        if (isActive(operator)) revert OperatorNotActive(operator);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address ledgerVault, address assetOwnership, address mmc) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
        LEDGER_VAULT = ILedgerVault(ledgerVault);
        ASSET_OWNERSHIP = IAssetOwnership(assetOwnership);
        MMC = mmc;
    }

    /// @notice Initializes the contract state.
    function initialize(address owner, uint256 expireAt) public initializer {
        __Ledger_init();
        __Pausable_init();
        __Ownable_init(owner);
        _setExpirationTime(expireAt);
    }

    /// @notice Checks if a given interface ID is supported by this contract.
    /// @param interfaceId The bytes4 identifier of the interface to check for support.
    /// @return A boolean indicating whether the interface ID is supported (true) or not (false).
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICampaign).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Pauses the contract, preventing certain functions from being executed.
    /// @dev Only the contract owner can call this function.
    /// Once paused, functions with the `whenNotPaused` modifier will be disabled.
    function pause() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /// @notice Resumes the contract, allowing paused functions to be executed again.
    /// @dev Only the contract owner can call this function.
    /// Once unpaused, functions with the `whenNotPaused` modifier will be enabled again.
    function unpause() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /// @notice Sets the maximum rate limit for an account within the campaign.
    /// @dev The rate limit determines the maximum number of accesses an account can sponsor.
    /// @param limit The maximum number of sponsored accesses allowed.
    function setMaxRateLimit(uint256 limit) external onlyOwner {
        require(limit > 0, "Rate limit must be greater than zero.");
        _setMaxRateLimit(limit);
    }

    /// @notice Allocates a specific amount of funds to an operator for the campaign.
    /// @dev The allocation represents the funds that can be handled
    ///      by the specified operator for each `run` of the campaign.
    /// @param amount The maximum amount of funds allocated per `run`.
    /// @param operator The operator authorized to operate over the allocated funds.
    function setFundsAllocation(uint256 amount, address operator) external onlyOwner {
        require(amount > 0, "Invalid zero funds allocation.");
        require(getLedgerBalance(msg.sender, MMC) >= amount, "Insufficient funds in campaign to allocate.");
        _setAllocation(operator, amount);
    }

    /// @notice Retrieves the maximum rate limit.
    /// @return The maximum rate limit allowed.
    function getMaxRateLimit() external view returns (uint256) {
        return _getRateLimit();
    }

    /// @notice  Retrieves the maximum allocated funds available for a specific operator in the campaign.
    /// @param operator The operator authorized to utilize the allocated funds.
    /// @return The allocated funds for the specified operator.
    function getFundsAllocation(address operator) external view returns (uint256) {
        return _getAllocation(operator);
    }

    /// @notice Retrieves the current rate counter for an account.
    /// @param account The account to retrieve the counter for.
    /// @return The current value of the sponsored access counter for the account.
    function getRateCounter(address account) external view returns (uint256) {
        return _getRateCounter(account);
    }

    /// @notice Retrieves the current balance of funds for a specific account in the campaign.
    /// @return The current funds balance of the specified account.
    function getFundsBalance() external view returns (uint256) {
        return getLedgerBalance(owner(), MMC);
    }

    /// @notice Adds funds to the campaign's balance.
    /// @param amount The amount of funds to add.
    function addFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount to allocate in campaign.");
        uint256 deposited = LEDGER_VAULT.collect(msg.sender, amount, MMC);
        _sumLedgerEntry(msg.sender, deposited, MMC);
        emit FundsAdded(deposited);
    }

    /// @notice Removes funds from the campaign's balance.
    /// @param amount The amount of funds to remove.
    function removeFunds(uint256 amount) external onlyOwner {
        require(getLedgerBalance(msg.sender, MMC) >= amount, "Insufficient funds allocated in campaign.");
        uint256 confirmed = LEDGER_VAULT.transfer(msg.sender, amount, MMC);
        _subLedgerEntry(msg.sender, confirmed, MMC);
        emit FundsRemoved(confirmed);
    }

    /// @notice Executes a campaign run for a given account.
    /// @dev Ensures proper allocation and rate limits during the execution:
    ///      1. Verifies the account has a valid allocation set for the operator.
    ///      2. Confirms the account has sufficient funds in the campaign.
    ///      3. Checks that the rate limit for the account has not been exceeded.
    /// @param account The account receiving the sponsored access.
    /// @return The amount of funds allocated during the `run`.
    function run(address account) external onlyWhenActiveFor(msg.sender) returns (uint256) {
        uint256 maxSponsoredAccess = _getRateLimit();
        uint256 allocatedAmount = _getAllocation(msg.sender);
        uint256 availableFunds = getLedgerBalance(owner(), MMC);
        uint256 currentRateCounter = _getRateCounter(account);

        require(allocatedAmount > 0, "No funds allocated for this campaign.");
        require(availableFunds >= allocatedAmount, "No funds to sponsor access in campaign.");
        require(maxSponsoredAccess > currentRateCounter, "Exceeded max sponsored access in campaign.");
        // Increment the access counter and deduct the allocated funds.
        _setRateCounter(account, currentRateCounter + 1);
        _subLedgerEntry(owner(), allocatedAmount, MMC);

        // Reserve the allocated funds for the campaign executor.
        LEDGER_VAULT.approve(msg.sender, allocatedAmount, MMC);
        emit CampaignRun(account, allocatedAmount);
        return allocatedAmount;
    }

    /// @notice Checks if a campaign is active for a specific operator.
    /// @param operator The address of the operator managing the campaign.
    /// @return True if the campaign is active for the given account and operator, otherwise false.
    function isActive(address operator) public view virtual returns (bool) {
        bool isExpired = _getExpirationTime() < block.timestamp;
        bool withValidSetup = _getRateLimit() > 0 && _getAllocation(operator) > 0;
        return withValidSetup && !isExpired && !paused();
    }

    /// @notice Returns the asset holder registered in the ownership contract.
    /// @param assetId the asset ID to retrieve the holder.
    function _getHolder(uint256 assetId) internal view returns (address) {
        return ASSET_OWNERSHIP.ownerOf(assetId); // Returns the registered owner.
    }

    /// @dev Retrieves the allocation for an operator.
    /// @param operator The operator managing the allocation.
    /// @return The allocated funds for the operator.
    function _getAllocation(address operator) internal view returns (uint256) {
        return _allocation[operator];
    }

    /// @dev Retrieves the current rate counter for an account.
    /// @param account The account to retrieve the counter for.
    /// @return The current value of the access counter.
    function _getRateCounter(address account) internal view returns (uint256) {
        return _rateCounter[account];
    }

    /// @dev Retrieves the expiration timestamp.
    /// @return The expiration timestamp.
    function _getExpirationTime() internal view returns (uint256) {
        return _expires;
    }

    /// @dev Retrieves the rate limit.
    /// @return The rate limit value.
    function _getRateLimit() internal view returns (uint256) {
        return _rateLimits;
    }

    /// @dev Updates the rate counter for an account.
    /// @param value The new counter value.
    function _setRateCounter(address account, uint256 value) internal {
        _rateCounter[account] = value;
        emit RateCounterUpdated(value);
    }

    /// @dev Updates the expiration timestamp for an account.
    /// @param expireAt The new expiration timestamp.
    function _setExpirationTime(uint256 expireAt) internal {
        _expires = block.timestamp + expireAt;
        emit ExpirationSet(_expires);
    }

    /// @notice Sets the maximum rate limit for the campaign.
    /// @dev This function updates the internal `_rateLimits` variable and emits an event.
    /// @param limit The new maximum number of accesses allowed per campaign.
    function _setMaxRateLimit(uint256 limit) internal {
        _rateLimits = limit;
        emit MaxRateLimitSet(limit);
    }

    /// @dev Updates the allocation for an account and operator.
    /// @param operator The operator managing the allocation.
    /// @param amount The allocation amount.
    function _setAllocation(address operator, uint256 amount) internal {
        _allocation[operator] = amount;
        emit FundsAllocationSet(operator, amount);
    }
}
