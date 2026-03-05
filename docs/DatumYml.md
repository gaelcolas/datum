# Datum.yml Configuration Reference

The `Datum.yml` file defines the structure, behaviour, and extensions of a Datum hierarchy. It is the central configuration file, placed at the root of your configuration data tree.

## Complete Example

The following example is modelled after the [DscWorkshop](https://github.com/dsccommunity/DscWorkshop) project, which is the reference implementation for Datum-based DSC configuration management.

```yaml
DatumStructure:
  - StoreName: AllNodes
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./AllNodes

  - StoreName: Environment
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./Environment

  - StoreName: Locations
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./Locations

  - StoreName: Roles
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./Roles

  - StoreName: Baselines
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./Baselines

  - StoreName: Global
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./Global

ResolutionPrecedence:
  - 'AllNodes\$($Node.Environment)\$($Node.NodeName)'
  - 'Environment\$($Node.Environment)'
  - 'Locations\$($Node.Location)'
  - 'Roles\$($Node.Role)'
  - 'Baselines\Security'
  - 'Baselines\$($Node.Baseline)'
  - 'Baselines\DscLcm'

default_lookup_options: MostSpecific

default_json_depth: 8

lookup_options:
  Configurations: Unique
  NetworkConfig: hash
  SoftwareBaseline: deep
  SoftwareBaseline\Packages:
    merge_hash_array: DeepTuple
    merge_options:
      tuple_keys:
        - Name

DatumHandlersThrowOnError: true

DscLocalConfigurationManagerKeyName: LcmConfig

DatumHandlers:
  Datum.ProtectedData::ProtectedDatum:
    CommandOptions:
      PlainTextPassword: true

  Datum.InvokeCommand::InvokeCommand:
    SkipDuringLoad: true
```

## Sections

### DatumStructure

Defines the root branches (stores) of the Datum tree. Each entry creates a top-level key in the Datum object.

```yaml
DatumStructure:
  - StoreName: <name>
    StoreProvider: <provider>
    StoreOptions:
      <provider-specific options>
```

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `StoreName` | string | Yes | Name of the root branch. Becomes a top-level key in `$Datum`. |
| `StoreProvider` | string | Yes | Provider to use. Built-in: `Datum::File`. |
| `StoreOptions` | hashtable | Yes | Options passed to the provider. |

#### Built-In File Provider Options

| Key | Type | Required | Default | Description |
|-----|------|----------|---------|-------------|
| `Path` | string | Yes | — | Relative or absolute path to the data directory. |

#### Multiple Stores

You can define multiple stores, each becoming a separate root branch:

```yaml
DatumStructure:
  - StoreName: AllNodes
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./AllNodes
  - StoreName: Roles
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./Roles
```

Access: `$Datum.AllNodes`, `$Datum.Roles`

#### Custom Store Providers

External store providers can be created as PowerShell modules. The `StoreProvider` value format is `<ModuleName>::<ProviderName>`, which maps to a `New-Datum<ProviderName>Provider` function in the specified module.

---

### ResolutionPrecedence

An ordered list of path prefixes, from **most specific** to **most generic**. When performing a lookup, Datum tries each path and returns or merges the values found.

```yaml
ResolutionPrecedence:
  - 'AllNodes\$($Node.Environment)\$($Node.NodeName)'
  - 'Environment\$($Node.Environment)'
  - 'Locations\$($Node.Location)'
  - 'Roles\$($Node.Role)'
  - 'Baselines\Security'
  - 'Baselines\$($Node.Baseline)'
  - 'Baselines\DscLcm'
```

#### Variable Substitution

Paths support PowerShell variable substitution using `$()` syntax. The `$Node` variable is the most commonly used, referring to the current node's metadata:

| Expression | Resolves To |
|-----------|-------------|
| `$($Node.Name)` | The node's file name in the `AllNodes` store (set by the FileProvider) |
| `$($Node.NodeName)` | The node's logical name (typically set in the data file itself) |
| `$($Node.Environment)` | The node's environment |
| `$($Node.Location)` | The node's location |
| `$($Node.Role)` | The node's role |
| `$($Node.Baseline)` | The node's baseline profile (e.g. `Server`) |

Any property of the node hashtable can be referenced.

> **Tip:** `$Node.Name` is the file name of the node data file (set automatically by the FileProvider). `$Node.NodeName` is typically set inside the data file itself, often using `'[x={ $Node.Name }=]'` via InvokeCommand to derive it from the file name.

#### Path Format

- Use **backslash** (`\`) as the path separator
- The first segment must match a `StoreName` from `DatumStructure`
- Subsequent segments map to directories or files within the store

#### Resolution Example

For a node with `Name = 'DSCWeb01'`, `NodeName = 'DSCWeb01'`, `Environment = 'Dev'`, `Location = 'Frankfurt'`, `Role = 'WebServer'`, `Baseline = 'Server'`:

```
AllNodes\Dev\DSCWeb01     →  $Datum.AllNodes.Dev.DSCWeb01.<PropertyPath>
Environment\Dev           →  $Datum.Environment.Dev.<PropertyPath>
Locations\Frankfurt       →  $Datum.Locations.Frankfurt.<PropertyPath>
Roles\WebServer           →  $Datum.Roles.WebServer.<PropertyPath>
Baselines\Security        →  $Datum.Baselines.Security.<PropertyPath>
Baselines\Server          →  $Datum.Baselines.Server.<PropertyPath>
Baselines\DscLcm          →  $Datum.Baselines.DscLcm.<PropertyPath>
```

---

### default_lookup_options

Sets the default merge strategy applied to all lookups. Can be a preset name or a detailed strategy hashtable.

```yaml
# Simple preset
default_lookup_options: MostSpecific

# Detailed configuration
default_lookup_options:
  merge_hash: deep
  merge_basetype_array: Unique
  merge_hash_array: DeepTuple
  merge_options:
    knockout_prefix: '--'
```

#### Available Presets

| Preset | Aliases | Description |
|--------|---------|-------------|
| `MostSpecific` | `First` | Return the first value found (no merge) |
| `hash` | `MergeTopKeys` | Merge top-level hashtable keys |
| `deep` | `MergeRecursively` | Recursively merge all nested structures |

See [Merging Strategies](Merging.md) for complete documentation.

---

### default_json_depth

Controls the depth passed to `ConvertTo-Json` when serializing objects in debug and verbose output. Prevents truncation warnings when working with deep data structures.

```yaml
default_json_depth: 8
```

| Type | Required | Default |
|------|----------|---------|
| integer | No | `4` |

Without this setting, deeply nested structures (more than 4 levels) may produce `"Resulting JSON is truncated as serialization has exceeded the set depth"` warnings during merge operations. Increase this value if your data hierarchy has very deep nesting.

---

### lookup_options

Per-key merge strategy overrides. Keys can be exact property paths or regex patterns.

```yaml
lookup_options:
  # Simple preset for a key
  Configurations: Unique

  # Detailed strategy for a key
  SoftwareBaseline\Packages:
    merge_hash_array: DeepTuple
    merge_options:
      tuple_keys:
        - Name
        - Version

  # Regex pattern (starts with ^)
  ^LCM_Config\\.*: deep
```

#### Key Matching

| Pattern Type | Example | Description |
|-------------|---------|-------------|
| Exact match | `Configurations` | Matches only the `Configurations` key |
| Nested path | `SoftwareBaseline\Packages` | Matches the `Packages` sub-key under `SoftwareBaseline` |
| Regex | `^Security\\.*` | Matches any key under `Security` |

Exact matches always take priority over regex matches.

For the full list of strategy properties (`merge_hash`, `merge_basetype_array`, `merge_hash_array`, `merge_options`) and their values, see [Merging Strategies](Merging.md#configuring-merge-strategies).

---

### DatumHandlers

Registers value transformation handlers that process values at lookup time.

```yaml
DatumHandlers:
  <ModuleName>::<HandlerName>:
    CommandOptions:
      <key>: <value>
    SkipDuringLoad: <bool>
```

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `CommandOptions` | hashtable | No | Parameters passed to the handler's action function |
| `SkipDuringLoad` | bool | No | If `true`, handler runs only at lookup time, not during initial file load |

The key `<ModuleName>::<HandlerName>` maps to filter and action functions in the specified module. See [Datum Handlers](DatumHandlers.md) for the naming convention, built-in handlers, and how to create custom handlers.

---

### Other Settings

#### DscLocalConfigurationManagerKeyName

When defined, specifies the key name within each node's data that contains LCM (Local Configuration Manager) settings. This is used during RSOP computation.

```yaml
DscLocalConfigurationManagerKeyName: LcmConfig
```

#### DatumHandlersThrowOnError

When `true`, handler errors propagate as terminating errors instead of being silently swallowed. **Recommended for production use.** See [Datum Handlers — Error Handling](DatumHandlers.md#error-handling) for details.

```yaml
DatumHandlersThrowOnError: true
```

### Global Data Stores

Not every store needs to appear in `ResolutionPrecedence`. Stores defined in `DatumStructure` but absent from `ResolutionPrecedence` act as **global data stores** — they are accessible through `$Datum.<StoreName>` but are never merged into a node's RSOP automatically.

This pattern is used for shared, non-node-specific data such as domain settings, Azure subscription details, or shared credentials:

```yaml
DatumStructure:
  # ... node-specific stores ...

  - StoreName: Global
    StoreProvider: Datum::File
    StoreOptions:
      Path: ./Global
```

Access global data directly:

```powershell
$Datum.Global.Domain.DomainFqdn       # → 'contoso.com'
$Datum.Global.Azure.SubscriptionId     # → 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

Or reference global data from within node/role data files via [Datum.InvokeCommand](DatumHandlers.md):

```yaml
# In a role or node data file
DomainName: '[x={ $Datum.Global.Domain.DomainFqdn }=]'
DomainJoinCredential: '[x={ $Datum.Global.Domain.DomainJoinCredentials }=]'
```

This keeps shared values in a single place while letting any layer reference them.

### Baselines Pattern

The **Baselines** pattern groups low-priority default data into multiple sub-layers that appear at the bottom of the resolution precedence. Each sub-layer represents a functional concern (security hardening, LCM configuration, etc.).

```yaml
ResolutionPrecedence:
  # ... higher-priority layers ...
  - 'Baselines\Security'           # Static — applies to all nodes
  - 'Baselines\$($Node.Baseline)'  # Dynamic — selected per node
  - 'Baselines\DscLcm'             # Static — LCM defaults for all nodes
```

Nodes select their dynamic baseline via a property:

```yaml
# AllNodes/Dev/DSCWeb01.yml
Baseline: Server
```

Baseline files contribute `Configurations`, security settings, and other defaults at the lowest priority, so any higher layer can override them:

```yaml
# Baselines/Security.yml
WindowsFeatures:
  Name:
    - -Telnet-Client     # Knockout prefix — ensures Telnet is removed

# Baselines/Server.yml
Configurations:
  - ComputerSettings
  - NetworkIpConfiguration
  - WindowsEventLogs
```

---

## File System Layout

A typical Datum configuration data tree (modelled after the [DscWorkshop](https://github.com/dsccommunity/DscWorkshop) reference implementation):

```
ConfigData/
├── Datum.yml                    # This configuration file
├── AllNodes/
│   ├── Dev/
│   │   ├── DSCFile01.yml        # Node-specific data
│   │   └── DSCWeb01.yml
│   ├── Prod/
│   │   └── DSCWeb02.yml
│   └── Test/
│       └── DSCFile02.yml
├── Environment/
│   ├── Dev.yml                  # Environment-level defaults
│   ├── Prod.yml
│   └── Test.yml
├── Locations/
│   ├── Frankfurt.yml            # Location-specific data
│   └── Singapore.yml
├── Roles/
│   ├── FileServer.yml           # Role definitions
│   ├── WebServer.yml
│   └── DomainController.yml
├── Baselines/
│   ├── Security.yml             # Static baseline — all nodes
│   ├── Server.yml               # Dynamic baseline — selected per node
│   └── DscLcm.yml               # Static baseline — LCM defaults
└── Global/
    ├── Domain.yml               # Shared domain settings (credentials, FQDN)
    └── Azure.yml                # Shared Azure subscription info
```

Each directory under a store becomes an intermediate node. Each `.yml`, `.json`, or `.psd1` file becomes a leaf with its parsed contents.

The `Global/` store is not in `ResolutionPrecedence` — it is accessed directly via `$Datum.Global.*` or referenced from data files using InvokeCommand expressions.

## See Also

- [README](../README.md) — Overview and getting started
- [Merging Strategies](Merging.md) — Complete merge behaviour reference
- [Datum Handlers](DatumHandlers.md) — Handler system documentation
- [Cmdlet Reference](CmdletReference.md) — All public function documentation
