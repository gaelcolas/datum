# Cmdlet Reference

Complete reference for all public functions exported by the Datum module.

## Core Lookup Functions

### New-DatumStructure

Creates a Datum hierarchy object from a `Datum.yml` configuration file or a hashtable definition. This is the entry point for all Datum operations.

**Parameter Sets:**

- `FromConfigFile` (default): Load from a YAML definition file
- `DatumHierarchyDefinition`: Provide a hashtable directly

```powershell
# From a definition file (most common)
$Datum = New-DatumStructure -DefinitionFile .\Datum.yml

# From a hashtable
$Datum = New-DatumStructure -DatumHierarchyDefinition @{
    DatumStructure = @(
        @{
            StoreName     = 'AllNodes'
            StoreProvider = 'Datum::File'
            StoreOptions  = @{ Path = './AllNodes' }
        }
    )
    ResolutionPrecedence = @(
        'AllNodes\$($Node.Name)'
    )
}
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `DefinitionFile` | `[System.IO.FileInfo]` | Yes* | — | Path to a Datum.yml configuration file |
| `DatumHierarchyDefinition` | `[hashtable]` | Yes* | — | Hashtable containing the hierarchy definition. Alias: `Structure` |
| `Encoding` | `[string]` | No | `'Default'` | File encoding. Values: Ascii, BigEndianUnicode, Default, Unicode, UTF32, UTF7, UTF8 |

*One of `DefinitionFile` or `DatumHierarchyDefinition` is required.

**Output:** `[hashtable]` — The Datum tree object with a `__Definition` key containing the hierarchy configuration.

---

### Resolve-NodeProperty

The primary lookup function for resolving configuration data from the hierarchy. This function wraps `Resolve-Datum` with DSC-friendly defaults including automatic fallback to `$ConfigurationData.Datum` and default value handling.

**Aliases:** `Lookup`, `Resolve-DscProperty`

```powershell
# Basic lookup
Resolve-NodeProperty -PropertyPath 'Configurations' -Node $Node -DatumTree $Datum

# Using the Lookup alias
Lookup 'Configurations' -Node $Node -DatumTree $Datum

# With a default value
Lookup 'OptionalSetting' -DefaultValue 'FallbackValue' -Node $Node -DatumTree $Datum

# In DSC context (automatically uses $Node and $ConfigurationData.Datum)
Lookup 'Configurations'
```

| Parameter | Type | Position | Required | Default | Description |
|-----------|------|----------|----------|---------|-------------|
| `PropertyPath` | `[string]` | 0 | Yes | — | Dot-notation or backslash-separated path to the property |
| `DefaultValue` | `[object]` | 1 | No | — | Value to return if the lookup finds nothing. AllowNull. |
| `Node` | `[object]` | 3 | No | `$Node` (from scope) | The node hashtable for variable substitution |
| `DatumTree` | `[object]` | — | No | `$ConfigurationData.Datum` | The Datum hierarchy object. Alias: `DatumStructure` |
| `SearchPaths` | `[string[]]` | — | No | — | Override the resolution precedence paths |
| `MaxDepth` | `[int]` | 5 | No | — | Maximum merge recursion depth. AllowNull. |

**Output:** `[System.Array]` — The resolved value(s).

**Behaviour Notes:**
- If `$DatumTree` is not provided, falls back to `$ConfigurationData.Datum`
- If `SearchPaths` is not provided, uses `$DatumTree.__Definition.ResolutionPrecedence`
- When a `DefaultValue` is specified and the lookup returns nothing, the default is returned
- If neither a result nor a default value is found, a warning is written

---

### Resolve-Datum

The core lookup engine. Resolves a property path through the hierarchy, applying merge strategies. `Resolve-NodeProperty` is a wrapper around this function.

```powershell
Resolve-Datum -PropertyPath 'Configurations' -Variable $Node -DatumTree $Datum
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `PropertyPath` | `[string]` | Yes | — | The property path to resolve |
| `Variable` | `[object]` | No | `$Node` (from scope) | The node/variable object. Alias: `Node` |
| `VariableName` | `[string]` | No | `'Node'` | Name of the variable for substitution |
| `DatumTree` | `[object]` | No | `$ConfigurationData.Datum` | The Datum hierarchy. Alias: `DatumStructure` |
| `Options` | `[hashtable]` | No | — | Merge options override. Alias: `SearchBehavior` |
| `PathPrefixes` | `[string[]]` | No | `$DatumTree.__Definition.ResolutionPrecedence` | Resolution paths. Alias: `SearchPaths` |
| `MaxDepth` | `[int]` | No | From definition or `-1` | Maximum merge recursion depth |

> **Note:** `PathPrefixes` are processed through configured datum
> handlers before lookup begins. Entries that resolve to `$null` or
> empty/whitespace strings (e.g. conditional `[x= ... =]` expressions)
> are automatically removed from the search list.

**Output:** `[System.Array]` — The resolved value(s).

---

### Merge-Datum

Merges two datum values using the specified merge strategy. Called internally by `Resolve-Datum` but can be used directly for custom merge operations.

```powershell
$merged = Merge-Datum -StartingPath 'MyKey' -ReferenceDatum $ref -DifferenceDatum $diff -Strategies @{
    '^.*' = 'deep'
}
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `StartingPath` | `[string]` | Yes | — | The current property path (used for strategy lookup) |
| `ReferenceDatum` | `[object]` | Yes | — | The higher-precedence (more specific) datum value |
| `DifferenceDatum` | `[object]` | Yes | — | The lower-precedence (more generic) datum value. AllowNull. |
| `Strategies` | `[hashtable]` | No | `@{ '^.*' = 'MostSpecific' }` | Merge strategies keyed by property path pattern |

**Output:** `[System.Array]` — The merged result.

---

## RSOP Functions

### Get-DatumRsop

Computes the **Resultant Set of Policy** for one or more nodes. This fully resolves and merges all hierarchy layers, producing the final configuration data for each node.

```powershell
$rsop = Get-DatumRsop -Datum $Datum -AllNodes $AllNodes
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Datum` | `[hashtable]` | Yes | — | The Datum hierarchy object |
| `AllNodes` | `[hashtable[]]` | Yes | — | Array of node hashtables |
| `CompositionKey` | `[string]` | No | `'Configurations'` | The key that lists which configurations to resolve |
| `Filter` | `[scriptblock]` | No | `{}` (no filter) | Filter to select specific nodes |
| `IgnoreCache` | `[switch]` | No | — | Skip the cache and force recalculation |
| `IncludeSource` | `[switch]` | No | — | Include source file information in the output |
| `RemoveSource` | `[switch]` | No | — | Strip internal `__File` NoteProperties from output values (mutually exclusive with `IncludeSource`; if both are specified, `IncludeSource` wins) |

For usage examples (filtering, source tracking, caching, composition key) see [RSOP](RSOP.md).

---

### Get-DatumRsopCache

Returns the current contents of the RSOP cache. No parameters. Returns the cache hashtable.

---

### Clear-DatumRsopCache

Clears the RSOP cache. Call this after modifying data files to ensure fresh results. No parameters. No output.

See [RSOP — Caching](RSOP.md#caching) for details.

---

## Data & Provider Functions

### New-DatumFileProvider

Creates a File Provider instance for a given file system path. The provider recursively scans the directory and builds a tree of data files. Used internally by `New-DatumStructure`.

```powershell
$provider = New-DatumFileProvider -Path './AllNodes'
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Store` | `[object]` | No | — | Store definition from DatumStructure config. Alias: `DataOptions` |
| `DatumHierarchyDefinition` | `[hashtable]` | No | `@{}` | The full hierarchy definition |
| `Path` | `[string]` | No | `$Store.StoreOptions.Path` | File system path to scan |
| `Encoding` | `[string]` | No | `'Default'` | File encoding |

**Output:** A `FileProvider` object that provides dot-notation access to the data tree.

---

### Get-FileProviderData

Reads and parses a single data file (YAML, JSON, or PSD1). Includes an internal file cache for performance.

```powershell
$data = Get-FileProviderData -Path './AllNodes/SRV01.yml'
$data = Get-FileProviderData -Path './config.json' -Encoding UTF8
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Path` | `[string]` | Yes | — | Path to the data file |
| `DatumHandlers` | `[hashtable]` | No | `@{}` | Handler definitions for value transformation |
| `Encoding` | `[string]` | No | `'Default'` | File encoding |

**Output:** `[System.Array]` — The parsed data (typically a hashtable).

**Supported Formats:**
- `.yml` / `.yaml` — YAML (requires powershell-yaml module)
- `.json` — JSON
- `.psd1` — PowerShell Data File

---

### ConvertTo-Datum

Converts input objects into Datum-compatible format, applying registered handlers. Handles ordered dictionaries, hashtables, arrays, and PSCustomObjects.

```powershell
$datumObject = $rawData | ConvertTo-Datum -DatumHandlers $handlers
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `InputObject` | `[object]` | No | — | The object to convert. Accepts pipeline input. |
| `DatumHandlers` | `[hashtable]` | No | `@{}` | Handler definitions for value transformation |

---

### Get-DatumSourceFile

Returns the relative source file path for a datum value. Used internally for RSOP source tracking when `-IncludeSource` is specified.

```powershell
$relativePath = Get-DatumSourceFile -Path 'C:\Config\AllNodes\SRV01.yml'
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Path` | `[string]` | Yes | — | Absolute path to resolve to a relative source path. AllowEmptyString. |

---

## Strategy Functions

### Get-MergeStrategyFromPath

Resolves the correct merge strategy for a given property path from the configured strategies. Checks for exact matches first, then regex patterns.

```powershell
$strategy = Get-MergeStrategyFromPath -Strategies $lookupOptions -PropertyPath 'SoftwareBaseline\Packages'
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Strategies` | `[hashtable]` | Yes | — | The lookup_options from Datum.yml |
| `PropertyPath` | `[string]` | Yes | — | The property path to find a strategy for |

**Output:** `[hashtable]` — The resolved merge strategy configuration.

---

### Resolve-DatumPath

Walks a path stack through the datum tree to resolve a value. Used internally by the lookup engine.

```powershell
$value = Resolve-DatumPath -Node $Node -DatumTree $Datum -PathStack @('AllNodes','DEV','SRV01') -PathVariables $vars
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Node` | `[object]` | No | — | The node object. Alias: `Variable` |
| `DatumTree` | `[object]` | No | — | The Datum hierarchy. Alias: `DatumStructure` |
| `PathStack` | `[string[]]` | No | — | Array of path segments to walk |
| `PathVariables` | `[ArrayList]` | No | — | Variables for path substitution |

**Output:** `[System.Array]` — The resolved value.

---

## Handler Functions

### Test-TestHandlerFilter

Built-in test handler filter function. Matches strings matching the pattern `[TEST=<data>]`.

```powershell
'[TEST=SomeValue]' | Test-TestHandlerFilter  # Returns $true
'plain string' | Test-TestHandlerFilter        # Returns $false
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `InputObject` | `[object]` | No | — | The value to test. Accepts pipeline input. |

**Output:** `[bool]`

---

### Invoke-TestHandlerAction

Built-in test handler action function. Returns diagnostic information about the handler invocation context.

```powershell
Invoke-TestHandlerAction -Password 'P@ssw0rd' -Test 'test' -Datum $Datum
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `Password` | `[string]` | No | — | From `CommandOptions` in Datum.yml |
| `Test` | `[object]` | No | — | From `CommandOptions` in Datum.yml |
| `Datum` | `[object]` | No | — | The Datum tree (auto-populated) |

**Output:** `[string]` — Diagnostic text showing the handler context.

---

## See Also

- [README](../README.md) — Overview and getting started
- [Merging Strategies](Merging.md) — Detailed merge behaviour documentation
- [Datum Handlers](DatumHandlers.md) — Handler system documentation
- [Datum.yml Reference](DatumYml.md) — Configuration file reference
