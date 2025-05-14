// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { LedgerUpgradeable } from "@synaps3/core/primitives/upgradeable/LedgerUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import { ILedgerVault } from "@synaps3/core/interfaces/financial/ILedgerVault.sol";
import { IAssetOwnership } from "@synaps3/core/interfaces/assets/IAssetOwnership.sol";
import { ICampaign } from "contracts/interfaces/ICampaign.sol";

/// @title CampaignBase
/// @notice Abstract contract for managing sponsored campaigns with funds allocation and access control.
abstract contract CampaignBase is
    Initializable,
    ERC165Upgradeable,
    LedgerUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ICampaign
{
    /// @dev Addresses are immutable to maintain consistent references and security.
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable MMC; // Token used for campaign transactions.

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ILedgerVault public immutable LEDGER_VAULT; // Handles ledger-based operations.

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IAssetOwnership public immutable ASSET_OWNERSHIP; // Manages asset ownership data.

    /// @dev Internal state variables that define campaign parameters.
    uint256 private _expires; // Timestamp when the campaign expires.
    uint256 private _quotaLimits; // Maximum allowed sponsored accesses (per account).
    uint256 private _globalQuotaCounter; // Tracks total usage of sponsored accesses across all accounts.

    /// @dev Mappings for operator-specific allocations and per-account usage.
    mapping(address => uint256) private _allocation; // Allocated funds per operator.
    mapping(address => uint256) private _quotaCounter; // Tracks how many sponsored accesses each account has used.

    /// @notice Emitted when new funds are added into the campaign.
    /// @param amount Amount of funds added.
    event FundsAdded(uint256 amount);

    /// @notice Emitted when funds are removed from the campaign.
    /// @param amount Amount of funds removed.
    event FundsRemoved(uint256 amount);

    /// @notice Emitted when the maximum quota limit (sponsored accesses) is set.
    /// @param limit The new maximum quota limit.
    event MaxQuotaLimitSet(uint256 limit);

    /// @notice Emitted when the campaign expiration time is updated.
    /// @param expiration The new expiration timestamp.
    event ExpirationSet(uint256 expiration);

    /// @notice Emitted when a quota counter is updated.
    /// @param counter The updated quota counter value.
    event QuotaCounterUpdated(uint256 counter);

    /// @notice Emitted when funds are allocated to an operator.
    /// @param operator The operator receiving the allocation.
    /// @param amount The amount of funds allocated.
    event FundsAllocationSet(address indexed operator, uint256 amount);

    /// @notice Emitted when a campaign run (`run`) is executed.
    /// @param account The account receiving sponsored access.
    /// @param amount The funds allocated during the run.
    event CampaignRun(address account, uint256 amount);

    /// @notice Thrown if a function is called by or for an operator that is not active.
    /// @param operator The inactive operator.
    error OperatorNotActive(address operator);

    /// @notice Ensures the specified operator is active before allowing function execution.
    /// @param operator The operator whose status is checked.
    /// @param account The account receiving sponsored access.
    modifier onlyWhenActiveFor(address operator, address account) {
        if (isActive(operator, account)) revert OperatorNotActive(operator);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @dev Initializes immutable references and disables initializers to prevent unauthorized usage.
    constructor(address ledgerVault, address assetOwnership, address mmc) {
        _disableInitializers();
        LEDGER_VAULT = ILedgerVault(ledgerVault);
        ASSET_OWNERSHIP = IAssetOwnership(assetOwnership);
        MMC = mmc;
    }

    /// @notice Initializes the contract with the owner, campaign description, and expiration time.
    /// @param owner Address that owns the campaign.
    /// @param expireAt Timestamp offset for campaign expiration.
    function initialize(address owner, uint256 expireAt) public initializer {
        __ERC165_init();
        __Ledger_init();
        __Pausable_init();
        __Ownable_init(owner);
        _setExpirationTime(expireAt);
    }

    /// @notice Indicates whether a given interface ID is supported by this contract.
    /// @param interfaceId The interface ID to check.
    /// @return True if supported; otherwise, false.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICampaign).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Pauses the contract, preventing certain functions from executing.
    /// @dev Only callable by the owner. Functions with `whenNotPaused` become unavailable.
    function pause() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /// @notice Resumes contract operations after a pause.
    /// @dev Only callable by the owner. Functions with `whenNotPaused` become available again.
    function unpause() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /// @notice Sets the maximum allowed sponsored accesses for each account.
    /// @dev Defines how many times an account can use sponsored access.
    /// @param limit The maximum number of sponsored accesses.
    function setQuotaLimit(uint256 limit) external onlyOwner {
        require(limit > 0, "Quota limit must be greater than zero.");
        _setMaxQuotaLimit(limit);
    }

    /// @notice Allocates a certain amount of campaign funds to an operator.
    /// @dev Each operator can spend up to the allocated amount in each `run`.
    /// @param amount Maximum funds allocated per operator usage.
    /// @param operator The operator allowed to spend allocated funds.
    function setFundsAllocation(uint256 amount, address operator) external onlyOwner {
        require(amount > 0, "Invalid zero funds allocation.");
        require(getFundsBalance() >= amount, "Insufficient funds in campaign to allocate.");
        _setAllocation(operator, amount);
    }

    /// @notice Retrieves the maximum sponsored access quota.
    /// @return The maximum number of times an account can use sponsored access.
    function getQuotaLimit() external view returns (uint256) {
        return _getQuotaLimit();
    }

    /// @notice Retrieves the allocated funds for a specified operator.
    /// @param operator The operator address.
    /// @return The amount of funds allocated to the operator.
    function getFundsAllocation(address operator) external view returns (uint256) {
        return _getAllocation(operator);
    }

    /// @notice Returns the total usage (number of times sponsored accesses have been used globally).
    /// @return Global count of sponsored accesses.
    function getTotalUsage() external view returns (uint256) {
        return _globalQuotaCounter;
    }

    /// @notice Retrieves the current quota counter for a given account.
    /// @param account The account to look up.
    /// @return The number of sponsored accesses used by this account.
    function getQuotaCounter(address account) external view returns (uint256) {
        return _getQuotaCounter(account);
    }

    /// @notice Adds funds to the campaign.
    /// @param amount Amount of tokens to deposit.
    function addFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount to allocate in campaign.");
        uint256 deposited = LEDGER_VAULT.collect(msg.sender, amount, MMC);
        _sumLedgerEntry(msg.sender, deposited, MMC);
        emit FundsAdded(deposited);
    }

    /// @notice Removes funds from the campaign.
    /// @param amount Amount of tokens to withdraw.
    function removeFunds(uint256 amount) external onlyOwner {
        require(getLedgerBalance(msg.sender, MMC) >= amount, "Insufficient funds allocated in campaign.");
        uint256 confirmed = LEDGER_VAULT.transfer(msg.sender, amount, MMC);
        _subLedgerEntry(msg.sender, confirmed, MMC);
        emit FundsRemoved(confirmed);
    }

    /// @notice Executes a campaign run for a specified account.
    /// @dev Checks allocation, available balance, and quota usage.
    /// @param account The account receiving sponsored access.
    /// @return The amount of allocated funds used during the run.
    function run(address account) external returns (uint256) {
        require(isActive(msg.sender, account), "Invalid inactive campaign.");
        uint256 allocatedAmount = _getAllocation(msg.sender);
        uint256 quotaCounter = _getQuotaCounter(account);

        // Increment usage counters and deduct allocated funds.
        _setQuotaCounter(account, quotaCounter + 1);
        _subLedgerEntry(owner(), allocatedAmount, MMC);
        _globalQuotaCounter++;

        // Approve allocated funds for the operator to spend.
        LEDGER_VAULT.approve(msg.sender, allocatedAmount, MMC);
        emit CampaignRun(account, allocatedAmount);
        return allocatedAmount;
    }

    /// @notice Retrieves the current campaign fund balance.
    /// @return The available fund balance within the campaign.
    function getFundsBalance() public view returns (uint256) {
        return getLedgerBalance(owner(), MMC);
    }

    /// @notice Checks if the campaign is ready to use.
    /// @dev A campaign is considered ready if:
    /// - The operator has an allocation greater than 0.
    /// - The campaign has a quota limit greater than 0.
    /// - There are available funds.
    /// @param operator The address of the operator managing the campaign.
    /// @return True if the campaign is ready, otherwise false.
    function isReady(address operator) public view returns (bool) {
        return _getAllocation(operator) > 0 && _getQuotaLimit() > 0 && getFundsBalance() > 0;
    }

    /// @notice Determines if the campaign is active or eligible for a given operator and account.
    /// @param operator The operator controlling the campaign.
    /// @param account The account to check usage state.
    /// @return True if the campaign is active for the operator-account pair; otherwise false.
    function isActive(address operator, address account) public view virtual returns (bool) {
        bool withValidSetup = isReady(operator);
        bool isExpired = _getExpirationTime() < block.timestamp;
        bool quotaLimitExceeded = _getQuotaCounter(account) >= _getQuotaLimit();
        bool fundsLimitExceeded = getFundsBalance() < _getAllocation(operator);
        // Campaign is active if setup is valid, not expired, not paused, and quota not exceeded.
        return withValidSetup && !isExpired && !paused() && !quotaLimitExceeded && !fundsLimitExceeded;
    }

    /// @notice Retrieves the owner of a given asset from the asset ownership contract.
    /// @param assetId The ID of the asset to look up.
    /// @return The address that owns the asset.
    function _getHolder(uint256 assetId) internal view returns (address) {
        return ASSET_OWNERSHIP.ownerOf(assetId);
    }

    /// @dev Returns the operator's fund allocation.
    /// @param operator The operator whose allocation is queried.
    /// @return The allocated fund amount.
    function _getAllocation(address operator) internal view returns (uint256) {
        return _allocation[operator];
    }

    /// @dev Returns the current quota counter for a specific account.
    /// @param account The account whose usage counter is queried.
    /// @return The number of sponsored accesses used.
    function _getQuotaCounter(address account) internal view returns (uint256) {
        return _quotaCounter[account];
    }

    /// @dev Returns the campaign expiration timestamp.
    /// @return The timestamp at which the campaign expires.
    function _getExpirationTime() internal view returns (uint256) {
        return _expires;
    }

    /// @dev Returns the campaign-wide maximum quota limit.
    /// @return The maximum number of sponsored accesses per account.
    function _getQuotaLimit() internal view returns (uint256) {
        return _quotaLimits;
    }

    /// @dev Sets a new quota counter value for an account.
    /// @param account The account to update.
    /// @param value The new quota counter.
    function _setQuotaCounter(address account, uint256 value) internal {
        _quotaCounter[account] = value;
        emit QuotaCounterUpdated(value);
    }

    /// @dev Sets the campaign expiration timestamp relative to the current block time.
    /// @param expireAt The offset in seconds to add to `block.timestamp`.
    function _setExpirationTime(uint256 expireAt) internal {
        _expires = block.timestamp + expireAt;
        emit ExpirationSet(_expires);
    }

    /// @dev Sets the global maximum quota limit and emits an event.
    /// @param limit The new maximum sponsored access limit.
    function _setMaxQuotaLimit(uint256 limit) internal {
        _quotaLimits = limit;
        emit MaxQuotaLimitSet(limit);
    }

    /// @dev Sets the allocation amount for an operator.
    /// @param operator The operator receiving the allocation.
    /// @param amount The amount to allocate.
    function _setAllocation(address operator, uint256 amount) internal {
        _allocation[operator] = amount;
        emit FundsAllocationSet(operator, amount);
    }
}
