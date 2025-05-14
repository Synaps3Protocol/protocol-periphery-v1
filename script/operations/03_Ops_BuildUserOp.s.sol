// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "forge-std/Script.sol";

import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { INonceManager } from "@account-abstraction/contracts/interfaces/INonceManager.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { console } from "forge-std/console.sol";

interface IERC4337 {
    function execute(address target, uint256 value, bytes calldata data) external payable returns (bytes memory);
}

contract OpsCreateOp is Script {
    function run() external view {
        address mmc = vm.envAddress("MMC");
        address paymaster = vm.envAddress("PAYMASTER");
        address sender = vm.envAddress("SMART_WALLET");
        address entrypoint = vm.envAddress("ENTRYPOINT");
        
        // https://eips.ethereum.org/EIPS/eip-4337
        uint128 callGas = 300000; // The amount of gas to allocate the main execution call
        uint128 verificationGas = 60000; // The amount of gas to allocate for the verification step
        uint128 maxPriorityFee = 40000000000; // Maximum priority fee per gas (similar to EIP-1559 max_priority_fee_per_gas)
        uint128 maxFeesPerGas = 40000000014; // Maximum fee per gas (similar to EIP-1559 max_fee_per_gas)
        uint256 preVerificationGas = 50000; // Extra gas to pay the bunder
        uint128 paymasterVerificationGasLimit = 60000; // The amount of gas to allocate for the paymaster validation code
        uint128 paymasterPostOpGasLimit = 60000; // The amount of gas to allocate for the paymaster post-operation code

        // concatenation of verificationGas (16 bytes) and callGas (16 bytes)
        bytes32 accountGasLimit = bytes32(abi.encodePacked(bytes16(verificationGas), bytes16(callGas)));
        // concatenation of maxPriorityFee (16 bytes) and maxFeePerGas (16 bytes)
        bytes32 gasFees = bytes32(abi.encodePacked(bytes16(maxPriorityFee), bytes16(maxFeesPerGas)));
        // bytes32 salt = bytes32(abi.encodePacked(0xEFBBD14082cF2FbCf5Badc7ee619F0f4e36D0A5B));
        // bytes memory callFactory = abi.encodeCall(
        //     ERC4337Factory.createAccount,
        //     (0xEFBBD14082cF2FbCf5Badc7ee619F0f4e36D0A5B, salt)
        // );

        // bytes memory initCode = abi.encodePacked(0xbeFb85F29Add5AD91f8646Be7b1d5090e4FaD89a, callFactory);
        bytes memory approve = abi.encodeCall(IERC20.approve, (0x037f2b49721E34296fBD8F9E7e9cc6D5F9ecE7b4, 50_000 * 1e18));
        bytes memory callData = abi.encodeCall(IERC4337.execute, (mmc, 0, approve)); //  execute(address target, uint256 value, bytes calldata data)

        uint256 nonce = INonceManager(entrypoint).getNonce(sender,0);
        PackedUserOperation memory op = PackedUserOperation({
            sender: sender, // predicted smart wallet
            nonce: nonce,
            initCode: "",
            callData: callData,
            // concatenation of verificationGas (16 bytes) and callGas (16 bytes)
            accountGasLimits: accountGasLimit,
            preVerificationGas: preVerificationGas,
            // concatenation of maxPriorityFee (16 bytes) and maxFeePerGas (16 bytes)
            gasFees: gasFees,
            paymasterAndData: abi.encodePacked(
                paymaster,
                bytes16(paymasterVerificationGasLimit),
                bytes16(paymasterPostOpGasLimit),
                ""
            ),
            signature: ""
        });

        bytes32 userOpHash = IEntryPoint(entrypoint).getUserOpHash(op);
        bytes32 digest = SignatureCheckerLib.toEthSignedMessageHash(userOpHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("PRIVATE_KEY"), digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        console.logUint(nonce);
        console.logBytes(signature);
        console.logBytes(callData);
    }
}
