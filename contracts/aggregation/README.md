# Aggregators Module

## Overview

The **Aggregation Module** provides a unified interface for accessing and consolidating data from multiple sources within the Synapse Protocol. This module simplifies complex queries by combining data from various core components, offering developers and external systems a single point of interaction for retrieving protocol-wide information.

Aggregators focus solely on **read operations**, enabling efficient data retrieval without modifying the state of the protocol. By centralizing data aggregation, the module reduces complexity and enhances the user experience.

---

## Purpose of Aggregation

The Aggregation Module is designed to:
1. **Simplify Data Access:**
   - Provide a single entry point for queries that require data from multiple sources or components.
   - Abstract the complexity of interacting with various contracts.

2. **Combine Data Across Domains:**
   - Fetch and aggregate data from different areas of the protocol, such as policies, attestations, rights, and governance.
   - Return cohesive and comprehensive results.

3. **Support Flexible Queries:**
   - Allow queries to be filtered or customized based on dynamic criteria (e.g., holder addresses, asset IDs, or policy terms).

4. **Enhance Developer Productivity:**
   - Reduce the need for developers to interact with individual contracts, minimizing the risk of errors and redundant code.

---

## Key Features

- **Cross-Domain Data Aggregation:**
  - Combine data from multiple sources, such as `RightsPolicyManager`, `RightsPolicyAuthorizer`, and `AssetOwnership`.

- **Dynamic Criteria Filtering:**
  - Support for encoded criteria (`abi.encode`) to enable flexible and reusable query logic.

- **Optimized Data Retrieval:**
  - Aggregate results into a single structure, minimizing the number of on-chain calls required by external systems.

- **Read-Only Operations:**
  - Focus exclusively on data retrieval, ensuring no state modifications within the protocol.

---

## Example Use Cases

1. **Fetch Policies by Holder:**
   - Retrieve all policies associated with a specific rights holder and their terms.

2. **Aggregate Data by Asset ID:**
   - Combine ownership and policy details for a given asset ID.

3. **Validate Access:**
   - Check if an account has access rights based on holder or asset criteria.

4. **Protocol-Wide Reporting:**
   - Provide aggregated metrics or insights into active policies, ownership distribution, or other system-wide data.

---

## Directory Structure

```plaintext
aggregators/
├── AccessAgg.sol          # Aggregates policies, attestations, and access rights
├── PolicyAgg.sol          # Focused on consolidating policy-related data
├── MetricsAgg.sol         # Aggregates protocol-wide metrics and statistics
└── README.md                     # Documentation for the Aggregators Module
