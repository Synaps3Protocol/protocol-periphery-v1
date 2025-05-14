// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title FractionalAccount
contract MultiSigAccount {
    // https://github.com/safe-global/safe-smart-account/blob/main/contracts/Safe.sol
    // TODO multisig smart accounts to create collaborations.
    // - Creator A (50%), Investor B (30%), Brand C (20%).
    // - Bounded group execution

//     Propose:
//     1. Define target, value, calldata (la acción)
//     2. Calculate operationHash = keccak256(abi.encode(target, value, calldata))
//     3. Save operationHash on-chain as pending proposal

//     Approve:
//     4. Each owner approves the operationHash (signing it or voting on-chain)

//     Execute:
//     5. When executing, recalculate operationHash based on (target, value, calldata)
//     6. Check if enough approvals exist for that specific hash
//     7. If yes, execute; if not, revert.

//     Hooks could be used to operate any additional actions = pre, during and post lifecycle
}
