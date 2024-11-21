// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DeployBase } from "script/deployment/00_Deploy_Base.s.sol";
import { Paymaster } from "contracts/infra/Paymaster.sol";
import { Paymaster } from "contracts/infra/Paymaster.sol";

contract DeployPaymaster is DeployBase {
    function run() external returns (address paymaster) {
        vm.startBroadcast(getAdminPK());
        bytes memory bytecode = type(Paymaster).creationCode;
        paymaster = deploy(bytecode, "SALT_PAYMASTER_ACCOUNT");
        vm.stopBroadcast();
        _logAddress("PAYMASTER", paymaster);
        return paymaster;
    }
}
