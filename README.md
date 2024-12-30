
# Periphery for Synapse Protocol

## Overview

The **Periphery Module** in Synapse Protocol serves as a critical extension layer that complements the core functionality of the system. While the **Core Module** focuses on the fundamental logic, rules, and security of the protocol, the Periphery is designed to implement specific dependencies, enhance interactions, and provide modular scalability without compromising the integrity of the core.

The Periphery is not a proxy or intermediary; rather, it acts as a dynamic and adaptable framework for extending the capabilities of the core.

```
Core Protocol
  ├── Policy Management
  ├── Access Control
  └── Hook Interface (IHookManager)

Peripheral
  ├── Hook Manager (central registry)
  ├── Custom Hooks (e.g., IAccessHook, IHookSplit)
  └── Extensions (e.g., Advanced Gating, Benefit Splitting)
```



---

## Concept and Role

The Periphery operates on three foundational principles:

1. **Specialization**  
   The Periphery implements specific dependencies of the core, such as policies, attestations, and hooks. These components are modular and can evolve independently, allowing the protocol to adapt to diverse use cases without altering the core logic.

2. **Abstraction**  
   The Periphery simplifies interactions with the core by grouping complex flows and providing utility functions that streamline operations. It reduces complexity for developers and users while maintaining the security and stability of the core.

3. **Extensibility**  
   By maintaining a clear separation of concerns, the Periphery enables seamless integration of new features, external services, and advanced functionalities like account abstraction. This design ensures that the protocol remains flexible and future-proof.

---

## Components of the Periphery

The Periphery encompasses several key areas that enhance the protocol's capabilities:

- **Policies**  
   Specialized logic to validate access and interactions within the protocol.
   
- **Attestations**  
   Mechanisms for proving and certifying specific conditions or properties required by policies.

- **Hooks**  
   Extensible points for executing custom logic during key interactions in the protocol.

- **Query Aggregation**  
   Utilities that combine multiple core interactions into simplified queries.

- **Account Abstraction**  
   Support for advanced account models, enabling features like signature validation and multisig compatibility.

- **External Integrations**  
   Modules for connecting the protocol to oracles, payment systems, and other external services.


## Why the Periphery Matters

- **Decoupled Design**  
   The Periphery ensures that the core remains focused on essential logic while allowing specialized components to be built and maintained separately.

- **Modular Evolution**  
   Changes to policies, attestations, or other periphery components do not require modifications to the core, making the protocol more robust and adaptable.

- **Enhanced Developer Experience**  
   By abstracting complex interactions, the Periphery simplifies the integration of Synapse into applications, fostering a broader ecosystem.


## Guiding Principles

1. **Core Stability:** The Periphery should never compromise the integrity or security of the core. All interactions must respect core-defined interfaces and rules.
2. **Flexibility:** The Periphery is designed to adapt quickly to new requirements and use cases.
3. **Transparency:** The separation between the core and periphery ensures clarity in responsibilities, promoting trust and reliability.

For more details on how to utilize or contribute to the Periphery Module, please refer to the protocol documentation or contact the development team.
