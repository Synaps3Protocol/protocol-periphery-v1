// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { IPaymaster } from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/// https://eips.ethereum.org/EIPS/eip-4337
contract Paymaster is IPaymaster {
    // verify that the paymaster is willing to pay for the operation
    function validatePaymasterUserOp(
        PackedUserOperation calldata,
        bytes32,
        uint256
    ) external pure override returns (bytes memory context, uint256 validationData) {
        // all the transactions are sponsored
        // this is a dummy temp testnet purpose paymaster to sponsor ops
        context = new bytes(0);
        validationData = 0;
    }

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external override {}
}
