// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { SmartAccounts } from "contracts/accounts/SmartAccounts.sol";

contract DeployAccountImpl is DeployBase {
    function run() external returns (address factory) {
        vm.startBroadcast(getAdminPK());
        bytes32 salt = getSalt("SALT_ACCOUNT_IMPL");
        bytes memory bytecode = type(SmartAccounts).creationCode;

        assembly {
            factory := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(factory)) {
                revert(0, 0)
            }
        }

        vm.stopBroadcast();
        _logAddress("ACCOUNT_IMPL", factory);
        return factory;
    }
}
