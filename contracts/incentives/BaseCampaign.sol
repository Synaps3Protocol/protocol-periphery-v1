// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { LedgerUpgradeable } from "@synaps3/core/primitives/upgradeable/LedgerUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";

import { IPolicy } from "@synaps3/core/interfaces/policies/IPolicy.sol";
import { ILedgerVault } from "@synaps3/core/interfaces/financial/ILedgerVault.sol";
import { FinancialOps } from "@synaps3/core/libraries/FinancialOps.sol";
import { ICampaign } from "contracts/interfaces/ICampaign.sol";

/// @title BaseCampaign
/// @notice Abstract contract for managing campaigns, including funds allocation, access control, and policy enforcement.
/// @dev Supports upgradeable contracts and integrates with Ledger and Access control modules.
abstract contract BaseCampaign is
    Initializable,
    UUPSUpgradeable,
    LedgerUpgradeable,
    PausableUpgradeable,
    AccessControlledUpgradeable,
    ICampaign
{
    using FinancialOps for address;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable MMC;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IPolicy public immutable POLICY;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ILedgerVault public immutable LEDGER_VAULT;

    /// @notice Maps an account to its maximum sponsored accesses allowed.
    mapping(address => uint256) private _rateLimits;
    /// @notice Tracks the number of sponsored accesses executed for an account.
    mapping(address => uint256) private _rateCounter;
    /// @notice Maps an account and a broker to the allocated funds for the campaign.
    mapping(address => mapping(address => uint256)) private _allocation;

    /// @notice Emitted when funds are added to a campaign.
    /// @param account The account that added funds.
    /// @param amount The amount of funds added.
    event FundsAdded(address account, uint256 amount);

    /// @notice Emitted when funds are removed from a campaign.
    /// @param account The account that removed funds.
    /// @param amount The amount of funds removed.
    event FundsRemoved(address account, uint256 amount);

    /// @notice Emitted when the maximum rate limit is set for an account.
    /// @param account The account whose rate limit was set.
    /// @param limit The new maximum rate limit.
    event MaxRateLimitSet(address indexed account, uint256 limit);

    /// @notice Emitted when funds are allocated to a broker for a campaign.
    /// @param account The account allocating the funds.
    /// @param broker The broker authorized to use the allocated funds.
    /// @param amount The amount of funds allocated.
    event PolicyAllocationSet(address indexed account, address indexed broker, uint256 amount);

    /// @notice Emitted when a campaign `run` is executed.
    /// @param sponsor The account sponsoring the campaign.
    /// @param account The account receiving sponsored access.
    /// @param amount The amount of funds allocated during the `run`.
    event CampaignRun(address indexed sponsor, address account, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address ledgerVault, address mmc, address policy) {
        /// Ensures the contract is properly initialized and prevents re-initialization.
        _disableInitializers();
        LEDGER_VAULT = ILedgerVault(ledgerVault);
        POLICY = IPolicy(policy); // The policy tied to this campaign.
        MMC = mmc;
    }


    // TODO isActiveCampaign(address, broker) => if ratio content >0 & allocated > 0 

    /// @notice Sets the maximum rate limit for an account within the campaign.
    /// @dev The rate limit determines the maximum number of accesses an account can sponsor.
    /// @param limit The maximum number of sponsored accesses allowed.
    function setMaxRateLimit(uint256 limit) external virtual {
        require(limit > 0, "Rate limit must be greater than zero.");
        _setRateLimit(msg.sender, limit);
        emit MaxRateLimitSet(msg.sender, limit);
    }

    /// @notice Retrieves the maximum rate limit for a specific account.
    /// @param account The account whose maximum rate limit is being queried.
    /// @return The maximum rate limit for the specified account.
    function getMaxRateLimit(address account) external view returns (uint256) {
        return _getRateLimit(account);
    }

    /// @notice Allocates a specific amount of funds to a broker for the campaign.
    /// @dev The allocation represents the funds that can be utilized
    ///      by the specified broker for each `run` of the campaign.
    /// @param amount The amount of funds to allocate per `run`.
    /// @param broker The broker authorized to operate over the allocated funds.
    function setPolicyAllocation(uint256 amount, address broker) external virtual {
        require(amount > 0, "Invalid zero funds allocation.");
        require(getLedgerBalance(msg.sender, MMC) >= amount, "Insufficient funds in campaign to allocate.");
        _setAllocation(msg.sender, broker, amount);
        emit PolicyAllocationSet(msg.sender, broker, amount);
    }

    /// @notice Retrieves the allocated funds for a specific broker.
    /// @param account The account providing the allocation.
    /// @param broker The broker managing the allocated funds.
    /// @return The allocated funds for the specified broker.
    function getPolicyAllocation(address account, address broker) external view virtual returns (uint256) {
        return _getAllocation(account, broker);
    }

    /// @notice Retrieves the current rate counter for an account.
    /// @param account The account to retrieve the counter for.
    /// @return The current value of the sponsored access counter for the account.
    function getRateCounter(address account) external view virtual returns (uint256) {
        return _getRateCounter(account);
    }

    /// @notice Retrieves the current balance of funds for a specific account in the campaign.
    /// @param account The account whose funds balance is being queried.
    /// @return The current funds balance of the specified account.
    function getFundsBalance(address account) external view returns (uint256) {
        return getLedgerBalance(account, MMC);
    }

    /// @notice Adds funds to the campaign's balance.
    /// @param amount The amount of funds to add.
    function addFunds(uint256 amount) external virtual {
        require(amount > 0, "Invalid amount to allocate in campaign.");
        uint256 deposited = LEDGER_VAULT.collect(msg.sender, amount, MMC);
        _sumLedgerEntry(msg.sender, deposited, MMC);
        emit FundsAdded(msg.sender, deposited);
    }

    /// @notice Removes funds from the campaign's balance.
    /// @param amount The amount of funds to remove.
    function removeFunds(uint256 amount) external virtual {
        require(getLedgerBalance(msg.sender, MMC) >= amount, "Insufficient funds allocated in campaign.");
        uint256 confirmed = LEDGER_VAULT.transfer(msg.sender, amount, MMC);
        _subLedgerEntry(msg.sender, confirmed, MMC);
        emit FundsRemoved(msg.sender, confirmed);
    }

    /// @notice Executes a campaign run for the implicit policy and a given account.
    /// @dev Ensures proper allocation and rate limits during the execution:
    ///      1. Verifies the account has a valid allocation set for the broker.
    ///      2. Confirms the account has sufficient funds in the campaign.
    ///      3. Checks that the rate limit for the account has not been exceeded.
    /// @param sponsor The account sponsoring the campaign.
    /// @param account The account receiving the sponsored access.
    /// @return The amount of funds allocated during the `run`.
    function run(address sponsor, address account) external virtual whenNotPaused returns (uint256) {
        uint256 maxSponsoredAccess = _getRateLimit(sponsor);
        uint256 policyAllocatedAmount = _getAllocation(sponsor, msg.sender);
        uint256 campaignAllocatedFunds = getLedgerBalance(sponsor, MMC);
        uint256 currentSponsoredAccessCount = _getRateCounter(account);

        require(policyAllocatedAmount > 0, "No policy allocation set for this campaign.");
        require(campaignAllocatedFunds >= policyAllocatedAmount, "No funds to sponsor access in campaign.");
        require(maxSponsoredAccess > currentSponsoredAccessCount, "Exceeded max sponsored access in campaign.");

        // Increment the access counter and deduct the allocated funds.
        _setRateCounter(account, currentSponsoredAccessCount + 1);
        _subLedgerEntry(sponsor, policyAllocatedAmount, MMC);
        // Reserve the allocated funds for the campaign executor.
        LEDGER_VAULT.reserve(msg.sender, policyAllocatedAmount, MMC);
        emit CampaignRun(sponsor, account, policyAllocatedAmount);
        return policyAllocatedAmount;
    }

    /// @dev Retrieves the allocation for an account and broker.
    /// @param account The account to retrieve the allocation for.
    /// @param broker The broker managing the allocation.
    /// @return The allocated funds for the broker.
    function _getAllocation(address account, address broker) internal view returns (uint256) {
        return _allocation[account][broker];
    }

    /// @dev Retrieves the current rate counter for an account.
    /// @param account The account to retrieve the counter for.
    /// @return The current value of the access counter.
    function _getRateCounter(address account) internal view returns (uint256) {
        return _rateCounter[account];
    }

    /// @dev Retrieves the rate limit for an account.
    /// @param account The account to retrieve the rate limit for.
    /// @return The rate limit value.
    function _getRateLimit(address account) internal view returns (uint256) {
        return _rateLimits[account];
    }

    /// @dev Updates the rate counter for an account.
    /// @param account The account to update the counter for.
    /// @param value The new counter value.
    function _setRateCounter(address account, uint256 value) private {
        _rateCounter[account] = value;
    }

    /// @dev Updates the rate limit for an account.
    /// @param account The account to update the rate limit for.
    /// @param limit The new rate limit value.
    function _setRateLimit(address account, uint256 limit) private {
        _rateLimits[account] = limit;
    }

    /// @dev Updates the allocation for an account and broker.
    /// @param account The account providing the allocation.
    /// @param broker The broker managing the allocation.
    /// @param amount The allocation amount.
    function _setAllocation(address account, address broker, uint256 amount) private {
        _allocation[account][broker] = amount;
    }
}
