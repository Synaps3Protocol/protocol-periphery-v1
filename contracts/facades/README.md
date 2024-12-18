# Facades

Facades represent specific logic within the system that directly interacts with the core. They serve as an abstraction layer, simplifying the complexity of protocol interactions and making them more accessible for users or external systems.

## Characteristics

- **Derived from the protocol**: Facades interact directly with the core logic without redefining it, offering a simplified interface.
- **Abstract complexity**: They encapsulate actions or multi-step processes into cohesive methods, whether for simple operations or more comprehensive workflows.
- **High-level and unified**: Facades provide a streamlined interface that hides intricate details of the protocol’s core components.
- **Modular and reusable**: Built to be reusable across the system, facades leverage existing core functionalities while maintaining consistency.
- **Adaptable**: Designed to address both specific actions and broader processes, facades align with practical, real-world use cases.
- **Intuitive interactions**: They simplify interactions by abstracting multiple dependencies, reducing the need for users to understand underlying complexities.

---

## Examples of Facades

### **Quick Agreement Creation**
This facade simplifies the process of creating an agreement by combining the deposit and agreement creation steps into a single, easy-to-use method.

```solidity
/// @notice Combines deposit and agreement creation in a single operation.
function createQuickAgreement(
    uint256 amount,
    address currency,
    address broker,
    address[] calldata parties,
    bytes calldata payload
) external returns (uint256) {
    // deposit funds into the vault
    uint256 depositedAmount = vault.deposit(msg.sender, amount, currency);
    // immediately create an agreement
    uint256 proof = agreementManager.createAgreement(depositedAmount, currency, broker, parties, payload);

    return proof;
}

```
### **Policy Registration Workflow**
This facade simplifies the process of creating an agreement by combining the deposit and agreement creation steps into a single, easy-to-use method.

``` solidity
/// @notice Simplifies policy registration by chaining agreement creation and policy registration steps.
function registerPolicyAgreement(
    uint256 amount,
    address holder,
    address policyAddress,
    address[] calldata parties,
    bytes calldata payload
) public returns (uint256) {
    address currency = address(MMC);
    address broker = address(RIGHTS_POLICY_MANAGER);
    // Step 1: Deposit the required amount into the Vault
    uint256 confirmedAmount = vault.deposit(msg.sender, amount, currency);
    // Step 2: Create the agreement using the confirmed deposit
    uint256 agreementProof = rightsAgreement.createAgreement(
        confirmedAmount,
        currency,
        broker,
        parties,
        payload
    );
    // Step 3: Register the policy using the created agreement
    return rightsPolicyManager.registerPolicy(agreementProof, holder, policyAddress);
}
```