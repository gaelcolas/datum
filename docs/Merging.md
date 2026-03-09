# Merging Strategies in Datum

Datum supports multiple merge strategies that control how values from different hierarchy layers are combined. This document covers all merge behaviours, data types, and configuration options.

## Data Types

When merging, Datum classifies values into four types:

| Type | Description | Examples |
|------|-------------|---------|
| **BaseType** | Scalar/simple values | `string`, `int`, `bool`, `DateTime`, `PSCredential` |
| **Hashtable** | Hashtable or OrderedDictionary | `@{ Key = 'Value' }` |
| **baseType_array** | Array of scalars | `@('a', 'b', 'c')` |
| **hash_array** | Array of hashtables | `@(@{ Name = 'x' }, @{ Name = 'y' })` |

An array is classified as `hash_array` if it can be cast as `[hashtable[]]`; otherwise it is a `baseType_array`.

## Strategy Presets

Datum provides three named presets that set defaults for all merge behaviours:

| Preset | Aliases | merge_hash | merge_baseType_array | merge_hash_array | knockout_prefix |
|--------|---------|-----------|---------------------|-----------------|----------------|
| **MostSpecific** | `First` | MostSpecific | MostSpecific | MostSpecific | _(none)_ |
| **hash** | `MergeTopKeys` | hash | MostSpecific | MostSpecific | `--` |
| **deep** | `MergeRecursively` | deep | Unique | DeepTuple | `--` |

### MostSpecific (Default)

Returns the **first value found** in the hierarchy — the most specific layer wins. No merging occurs.

### hash (MergeTopKeys)

Merges **top-level keys** of hashtables. If the same key exists in multiple layers, the most specific value wins. Keys that only exist in less-specific layers are included.

```yaml
# Role (generic)
NetworkConfig:
  DNSServer: 10.0.0.1
  Gateway: 10.0.0.254
  SubnetMask: 255.255.255.0

# Node (specific)
NetworkConfig:
  DNSServer: 192.168.1.1
```

With `hash` strategy, the result is:

```yaml
NetworkConfig:
  DNSServer: 192.168.1.1      # from Node (override)
  Gateway: 10.0.0.254          # from Role (kept)
  SubnetMask: 255.255.255.0    # from Role (kept)
```

### deep (MergeRecursively)

Like `hash`, but recursively merges nested hashtables and merges arrays. This is the most comprehensive merge strategy.

## Merge Behaviours by Data Type

### BaseType Merging

Base types (scalars) always use **MostSpecific** — the first value found wins.

```yaml
# Role
Timezone: 'UTC'

# Node
Timezone: 'Pacific Standard Time'
```

Result: `Pacific Standard Time` (from Node, the most specific layer).

### Hashtable Merging (merge_hash)

| Strategy | Behaviour |
|----------|-----------|
| **MostSpecific** | Return the entire hashtable from the most specific layer |
| **hash** | Merge top-level keys; most specific value wins per key |
| **deep** | Recursively merge all nested keys |

### Base-Type Array Merging (merge_baseType_array)

| Strategy | Behaviour |
|----------|-----------|
| **MostSpecific** | Return the array from the most specific layer |
| **Unique** | Combine arrays, removing duplicates |
| **Sum** | Concatenate arrays (may contain duplicates) |

Example with **Unique**:

```yaml
# Role
WindowsFeatures:
  - Telnet-Client
  - File-Services
  - Web-Server

# Node
WindowsFeatures:
  - Web-Server
  - SMTP-Server
```

Result: `Telnet-Client`, `File-Services`, `Web-Server`, `SMTP-Server` (union, duplicates removed).

### Hash-Array Merging (merge_hash_array)

Hash arrays — arrays of hashtables — have more sophisticated merge options using **tuple keys** to match items across layers.

| Strategy | Behaviour |
|----------|-----------|
| **MostSpecific** | Return the array from the most specific layer |
| **Sum** | Concatenate arrays |
| **UniqueKeyValTuples** | Combine arrays, de-duplicating by tuple key values |
| **DeepTuple** | Match items by tuple keys and deep-merge their properties |

#### Tuple Keys

When using `UniqueKeyValTuples` or `DeepTuple`, you must specify which keys identify matching items:

```yaml
lookup_options:
  Packages:
    merge_hash_array: DeepTuple
    merge_options:
      tuple_keys:
        - Name
```

#### DeepTuple Example

```yaml
# Role
Packages:
  - Name: NotepadPlusplus
    Version: '7.0'
    Ensure: Present
  - Name: Putty
    Ensure: Present

# Node
Packages:
  - Name: NotepadPlusplus
    Version: '8.0'
```

With `DeepTuple` and `tuple_keys: [Name]`, items with the same `Name` are matched and deep-merged:

```yaml
Packages:
  - Name: NotepadPlusplus
    Version: '8.0'           # overridden by Node
    Ensure: Present           # kept from Role
  - Name: Putty
    Ensure: Present           # kept from Role (no Node override)
```

#### UniqueKeyValTuples Example

Like DeepTuple, but matched items are replaced entirely rather than deep-merged. Items from the most specific layer take priority.

## Configuring Merge Strategies

### Global Default

Set the default strategy for all lookups in `Datum.yml`:

```yaml
default_lookup_options: MostSpecific
```

### Per-Key Overrides

Override the strategy for specific keys:

```yaml
lookup_options:
  Configurations: Unique
  NetworkConfig: hash
  Packages:
    merge_hash_array: DeepTuple
    merge_options:
      tuple_keys:
        - Name
```

### Custom Strategy Structure

For fine-grained control, specify individual merge behaviours:

```yaml
lookup_options:
  MyKey:
    merge_hash: deep
    merge_basetype_array: Unique
    merge_hash_array: DeepTuple
    merge_options:
      knockout_prefix: '--'
      tuple_keys:
        - Name
        - Version
```

### Regex-Based Lookup Options

Keys starting with `^` are treated as regex patterns:

```yaml
lookup_options:
  ^LCM_Config\\.*: deep
  ^Security\\.*:
    merge_hash: deep
    merge_basetype_array: Unique
```

Exact key matches are always preferred over regex matches.

## Knockout Prefix

The **knockout prefix** (default: `--`) removes items during merge. It is enabled by the `hash` and `deep` presets, or can be configured per key.

### Knocking Out Array Items

```yaml
# Role (generic)
WindowsFeatures:
  - Telnet-Client
  - File-Services
  - Web-Server

# Node (specific, with knockout)
WindowsFeatures:
  - --Telnet-Client
```

With `Unique` or `Sum` merge strategy, the result excludes `Telnet-Client`:

```yaml
WindowsFeatures:
  - File-Services
  - Web-Server
```

Both the knockout item (`--Telnet-Client`) and the matching original (`Telnet-Client`) are removed from the result.

### Knocking Out Hashtable Keys

Prefix a key with `--` to remove it during hash merge:

```yaml
# Role
Settings:
  FeatureA: enabled
  FeatureB: enabled
  FeatureC: enabled

# Node
Settings:
  --FeatureB:
```

Result: `FeatureA` and `FeatureC` remain; `FeatureB` is removed.

### Knocking Out Hash-Array Items

When merging hash arrays with tuple-based strategies, prefix the tuple key value:

```yaml
# Role
Packages:
  - Name: NotepadPlusplus
  - Name: Putty
  - Name: Git

# Node
Packages:
  - Name: --Putty
```

Result: `NotepadPlusplus` and `Git` remain; `Putty` is removed.

## Subkey Merge Behaviour

Merge strategies apply at the lookup level. If you want merged data within a nested key, you must declare strategies at **each level**:

```yaml
lookup_options:
  SoftwareBaseline: hash                    # merge top-level keys of SoftwareBaseline
  SoftwareBaseline\Packages:                # also merge the nested Packages array
    merge_hash_array: DeepTuple
    merge_options:
      tuple_keys:
        - Name
```

**Why this matters:**

Without the `SoftwareBaseline: hash` entry, a lookup of `SoftwareBaseline` returns the most specific value without merging — and the `Packages` merge rule is never reached.

However, a **direct lookup** of `SoftwareBaseline\Packages` works because it bypasses the top-level and looks up the nested key directly.

```powershell
# These can return different results depending on merge configuration:
Lookup 'SoftwareBaseline'                # governed by SoftwareBaseline strategy
(Lookup 'SoftwareBaseline').Packages     # no deep merge applied to Packages
Lookup 'SoftwareBaseline\Packages'       # governed by SoftwareBaseline\Packages strategy
```

## See Also

- [README - Lookup Merging Behaviour](../README.md#lookup-merging-behaviour)
- [Datum.yml Reference](DatumYml.md)
- [DSC Workshop Repository](https://github.com/dsccommunity/DscWorkshop/)
