// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { SmartAccount } from "contracts/accounts/SmartAccount.sol";

contract DeployAccountImpl is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());
        bytes memory bytecode = type(SmartAccount).creationCode;
        address impl = deploy(bytecode, "SALT_ACCOUNT_IMPL");
        vm.stopBroadcast();
        
        _logAddress("ACCOUNT_IMPL", impl);
        return impl;
    }
}
