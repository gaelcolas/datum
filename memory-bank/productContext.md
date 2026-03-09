# Product Context

## Why Datum Exists
Managing DSC Configuration Data at scale is a significant challenge. Without a hierarchical system, teams face:
- **Data duplication**: Repeating the same configuration across many nodes
- **Snowflake servers**: Each node becomes a unique special case
- **Merge complexity**: No standardized way to combine default and override values
- **Policy drift**: Hard to enforce consistent baselines when data is scattered

Datum solves these by providing a **Hiera-like hierarchy** for PowerShell DSC, enabling Roles & Profiles patterns used in mature configuration management ecosystems.

## How It Works
1. **Define a hierarchy** in `Datum.yml` with ordered layers (most specific to most generic)
2. **Store configuration data** in YAML/JSON/PSD1 files organized by layer (AllNodes, Environments, Roles, etc.)
3. **Lookup data** using `Resolve-Datum` or `Lookup` (alias), which walks the hierarchy and resolves values based on the current Node context
4. **Merge strategies** control how data from multiple layers combines (MostSpecific, hash merge, deep recursive merge)
5. **Data handlers** extend data types beyond simple values (encrypted credentials, dynamic expressions)

## User Experience Goals
- **Simple for operators**: Define a Role in YAML, assign it to nodes — no PowerShell or DSC expertise needed for day-to-day work
- **Powerful for architects**: Full control over merge strategies, resolution precedence, and data handler extensibility
- **Self-documenting**: The data hierarchy IS the documentation of your infrastructure policy
- **Version-controlled**: All config data lives in files (YAML/JSON/PSD1), perfect for git workflows

## Target Users
- **Infrastructure teams** managing Windows servers with DSC
- **DevOps engineers** implementing Infrastructure as Code
- **Configuration management specialists** migrating from Puppet/Chef/Ansible patterns
- Used in production managing **hundreds of machines**

## Key User Workflows
1. **New node onboarding**: Create a minimal YAML file (name, role, location) → node inherits all role policies
2. **Policy updates**: Change a Role definition → all implementing nodes get the update
3. **Exception handling**: Override specific values at node/location/environment level without touching the role
4. **RSOP (Resultant Set of Policy)**: Use `Get-DatumRsop` to see the fully resolved configuration for any node
