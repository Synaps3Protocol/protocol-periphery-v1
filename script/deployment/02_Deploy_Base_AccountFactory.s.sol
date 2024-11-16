// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { SmartAccounts } from "contracts/accounts/SmartAccounts.sol";
import { ERC4337Factory } from "solady/accounts/ERC4337Factory.sol";

contract DeployAccountFactory is DeployBase {
    function run() external returns (address factory) {

        vm.startBroadcast(getAdminPK());
        bytes32 salt = getSalt("SALT_ACCOUNT_FACTORY");
        bytes32 impSalt = getSalt("SALT_ACCOUNT_IMPL");
        bytes memory bytecode = type(ERC4337Factory).creationCode;
        bytes memory implBytecode = type(SmartAccounts).creationCode;
        address impl = vm.computeCreate2Address(impSalt, implBytecode, address(this));


        assembly {
            factory := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(factory)) {
                revert(0, 0)
            }
        }
        
        vm.stopBroadcast();
        _logAddress("ACCOUNT_FACTORY", factory);
        return factory;
    }
}
