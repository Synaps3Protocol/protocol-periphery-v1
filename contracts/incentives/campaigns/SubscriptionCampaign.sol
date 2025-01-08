// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import { BaseCampaign } from "contracts/incentives/BaseCampaign.sol";

contract SubscriptionCampaign is BaseCampaign {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address ledgerVault, address mmc, address policy) BaseCampaign(ledgerVault, mmc, policy) {}

    /// @notice Initializes the contract state.
    /// @param accessManager The address of the access manager.
    function initialize(address accessManager) public initializer {
        __Ledger_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessManager);
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
