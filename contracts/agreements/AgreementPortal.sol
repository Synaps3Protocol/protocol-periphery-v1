// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { FinancialOps } from "@synaps3/core/libraries/FinancialOps.sol";
import { AccessControlledUpgradeable } from "@synaps3/core/primitives/upgradeable/AccessControlledUpgradeable.sol";
import { IRightsPolicyManager } from "@synaps3/core/interfaces/rights/IRightsPolicyManager.sol";
import { IRightsAccessAgreement } from "@synaps3/core/interfaces/rights/IRightsAccessAgreement.sol";

contract AgreementPortal is Initializable, UUPSUpgradeable, AccessControlledUpgradeable {
    using FinancialOps for address;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsPolicyManager public immutable RIGHTS_POLICY_MANAGER;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRightsAccessAgreement public immutable RIGHTS_AGREEMENT;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable MMC;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address rightsPolicyManager, address rightsAgreement, address mmc) {
        /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
        /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
        _disableInitializers();
        RIGHTS_POLICY_MANAGER = IRightsPolicyManager(rightsPolicyManager);
        RIGHTS_AGREEMENT = IRightsAccessAgreement(rightsAgreement);
        MMC = IERC20(mmc);
    }

    /// @notice Initializes the proxy state.
    function initialize(address accessManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Creates and registers a new policy agreement in a single transaction.
    /// @param amount The amount of MMC tokens to be involved in the agreement.
    /// @param holder The address of the rights holder.
    /// @param policyAddress The address of the policy contract being used.
    /// @param parties An array of addresses representing the parties involved in the agreement.
    /// @param payload Additional data required for the agreement creation.
    function flashPolicyAgreement(
        uint256 amount,
        address holder,
        address policyAddress,
        address[] calldata parties,
        bytes calldata payload
    ) public returns (uint256) {
        address currency = address(MMC);
        address broker = address(RIGHTS_POLICY_MANAGER);
        // deposit from sender the amount
        // increase allowance to rights agreement
        uint256 confirmed = msg.sender.safeDeposit(amount, currency); 
        address(RIGHTS_AGREEMENT).increaseAllowance(confirmed, currency);
        // create immediately the agreement and use it to register the policy
        uint256 proof = RIGHTS_AGREEMENT.createAgreement(confirmed, currency, broker, parties, payload);
        return RIGHTS_POLICY_MANAGER.registerPolicy(proof, holder, policyAddress);
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
