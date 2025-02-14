// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { SmartAccounts } from "contracts/accounts/SmartAccounts.sol";
import { ERC4337Factory } from "solady/accounts/ERC4337Factory.sol";

contract DeployAccountFactory is DeployBase {
    function run() external returns (address) {
        vm.startBroadcast(getAdminPK());
        address impl = computeCreate3Address("SALT_ACCOUNT_IMPL");
        bytes memory bytecode = type(ERC4337Factory).creationCode;
        bytes memory initCode = abi.encodePacked(bytecode, abi.encode(impl));
        address factory = deploy(initCode, "SALT_ACCOUNT_FACTORY");
        vm.stopBroadcast();
        
        _logAddress("ACCOUNT_FACTORY", factory);
        return factory;
    }
}
