# Datum
## about_Datum

# Short Description
Datum is a PowerShell module that manages configuration data in a
hierarchical model, enabling lookup and merge of values from
multiple layers of data files (YAML, JSON, PSD1).

# Long Description
Datum provides a way to organise configuration data into layers,
where generic defaults can be overridden by more specific values.
This is especially useful for managing DSC (Desired State
Configuration) data at scale, but can be used anywhere
hierarchical data lookup is needed.

A Datum hierarchy is defined by a Datum.yml file that specifies:
- Data store branches (e.g. AllNodes, Roles, Environments)
- Resolution precedence (most specific to most generic)
- Default and per-key merge strategies
- Datum handlers for value transformation

## Core Concepts

### Hierarchy and Resolution Precedence
Data is organised in layers (e.g. Node, Location, Environment,
Role). A lookup walks the layers in order from most specific to
most generic and returns the first value found, or merges values
according to the configured merge strategy.
See [Datum.yml Reference](DatumYml.md) for configuration details.

### Merge Strategies
Datum supports several merge strategies (MostSpecific, hash,
deep) with per-key overrides.
See [Merging Strategies](Merging.md) for full documentation.

### Data Formats
The built-in File Provider reads YAML, JSON, and PSD1 files.
YAML is the most commonly used format. All formats are unified
under a consistent dot-notation access pattern.

### Datum Handlers
Handlers transform values at lookup time (e.g. decrypting
credentials or evaluating dynamic expressions).
See [Datum Handlers](DatumHandlers.md) for full documentation.

### RSOP (Resultant Set of Policy)
Get-DatumRsop computes the fully resolved configuration data
for one or more nodes, applying all hierarchy layers, merge
strategies and handlers.
See [RSOP](RSOP.md) for full documentation.

## Key Functions

See [Cmdlet Reference](CmdletReference.md) for complete
parameters and usage of all public functions.

### Resolve-NodeProperty (aliases: Lookup, Resolve-DscProperty)
The primary lookup function. Resolves a property path through
the hierarchy for a given node.

    Resolve-NodeProperty -PropertyPath 'Configurations' `
        -Node $Node -DatumTree $Datum

### New-DatumStructure
Creates a Datum hierarchy object from a Datum.yml definition.

    $Datum = New-DatumStructure -DefinitionFile .\Datum.yml

### Get-DatumRsop
Computes the Resultant Set of Policy for all or filtered nodes.

    $rsop = Get-DatumRsop -Datum $Datum -AllNodes $AllNodes

# Examples

## Example 1: Basic Hierarchy Lookup

    $Datum = New-DatumStructure -DefinitionFile .\Datum.yml
    $Node = @{ NodeName = 'SRV01'; Role = 'WebServer' }
    Lookup 'Configurations' -Node $Node -DatumTree $Datum

## Example 2: RSOP for All Nodes

This pattern works for both flat (`AllNodes/SRV01.yml`) and
nested (`AllNodes/Dev/SRV01.yml`) AllNodes layouts:

    $Datum = New-DatumStructure -DefinitionFile .\Datum.yml
    $AllNodes = @(
        foreach ($property in $Datum.AllNodes.psobject.Properties) {
            $node = $Datum.AllNodes.($property.Name)
            if ($node -is [System.Collections.IDictionary]) {
                @{} + $node
            }
            else {
                foreach ($childProperty in $node.psobject.Properties) {
                    @{} + $node.($childProperty.Name)
                }
            }
        }
    )
    $rsop = Get-DatumRsop -Datum $Datum -AllNodes $AllNodes

## Example 3: Using Default Values

    $value = Lookup 'SomeProperty' -Node $Node `
        -DatumTree $Datum -DefaultValue 'FallbackValue'

# Note
Datum requires the powershell-yaml module. Install it from the
PowerShell Gallery:

    Install-Module -Name datum -Scope CurrentUser

Optional modules for extended functionality:
- Datum.ProtectedData (encrypted credentials)
- Datum.InvokeCommand (dynamic expressions)

Datum works on PowerShell 5.1 and PowerShell 7+.

# Troubleshooting
If lookups return unexpected values, check:
- Resolution precedence order in Datum.yml
- Merge strategy configuration for the key
- Variable substitution in path prefixes (uses $Node)
- RSOP cache (call Clear-DatumRsopCache to reset)

If RSOP results seem stale, the cache may contain old data.
Use Clear-DatumRsopCache or pass -IgnoreCache to
Get-DatumRsop.

If you see `WARNING: Resulting JSON is truncated as
serialization has exceeded the set depth` during merge
operations, your data hierarchy exceeds the default
`ConvertTo-Json` depth. Set `default_json_depth` in
`Datum.yml` to a higher value (default: `4`). See
[Datum.yml — default_json_depth](DatumYml.md#default_json_depth)
for details.

# See Also
- [Merging Strategies](Merging.md)
- [Datum Handlers](DatumHandlers.md)
- [Code Layers](CodeLayers.md)
- DSC Workshop: https://github.com/dsccommunity/DscWorkshop/
- PowerShell Gallery: https://www.powershellgallery.com/packages/datum

# Keywords
- Datum
- DSC
- Configuration Data
- Hiera
- Hierarchy
- Lookup
- Merge
- RSOP
