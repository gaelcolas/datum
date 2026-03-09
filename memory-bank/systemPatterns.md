# System Patterns

## Architecture Overview
Datum follows a **provider-based hierarchical data resolution** architecture with these core components:

### Class Hierarchy
`
DatumProvider (base class)
  └── FileProvider (built-in, filesystem-based)
Node (extends Hashtable, represents a DSC node)
`

### Core Components

#### 1. Datum Structure (`New-DatumStructure`)
- Entry point: loads hierarchy from `Datum.yml` or hashtable definition
- Creates root branches by instantiating store providers (e.g., `FileProvider`)
- Stores the `__Definition` (resolution precedence, merge options, datum handlers)

#### 2. FileProvider (`source/Classes/FileProvider.ps1`)
- Mounts a filesystem directory as a datum store
- Directories become nested properties (lazy-loaded via ScriptProperty)
- Files are read on-demand via `Get-FileProviderData`
- Supports YAML, JSON, PSD1 formats
- Dot notation traversal: `.AllNodes.DEV.SRV01`

#### 3. Resolution Engine (`Resolve-Datum`)
- Walks ResolutionPrecedence paths with variable substitution
- For each prefix: expands `` references, appends the property path
- Returns first match (MostSpecific) or merges across layers based on strategy
- 285 lines — the most complex function in the module

#### 4. Merge Engine (`Merge-Datum`, `Merge-Hashtable`, `Merge-DatumArray`)
- 4 data types: BaseType, Hashtable, Array of Hashtables, Array of BaseTypes
- Merge strategies per type:
  - **BaseType**: Always returns most specific (no merge)
  - **Hashtable**: MostSpecific | hash (merge top keys) | deep (recursive)
  - **Array of BaseType**: MostSpecific | Sum/Add | Unique
  - **Array of Hashtables**: MostSpecific | Sum | DeepTuple (merge by tuple keys) | UniqueKeyValTuples
- Knockout prefix (`--`) to remove inherited items

#### 5. RSOP Engine (`Get-DatumRsop`)
- Resolves a complete picture of all configurations for a node
- Caches results per node name (``)
- Supports source tracking and cache management
- Source tracking detail: Every resolved value carries a `__File` NoteProperty (attached during resolution). Three output modes:
  - Default: Returns raw cached objects (NoteProperties present but invisible to YAML serialization)
  - `-IncludeSource`: Processes via `Expand-RsopHashtable` → `Get-RsopValueString` with `-AddSourceInformation`, producing strings with right-aligned file path annotations (column width controlled by `$env:DatumRsopIndentation`, default 120)
  - `-RemoveSource`: Processes via `Expand-RsopHashtable` → `Get-RsopValueString` without `-AddSourceInformation`, returning `.psobject.BaseObject` to strip `__File` NoteProperties
- `-IncludeSource` and `-RemoveSource` are mutually exclusive (`if/elseif` — IncludeSource wins when both specified)

#### 6. Data Handlers (`Invoke-DatumHandler`, `ConvertTo-Datum`)
- Extensible handler system via `DatumHandlers` in `Datum.yml`
- Pattern-matched: handler fires when data matches a regex filter
- External modules: `Datum.ProtectedData` (credentials), `Datum.InvokeCommand` (expressions)

### Key Design Patterns
- **Provider Pattern**: Abstracted data sources behind a common interface (DatumProvider)
- **Lazy Evaluation**: FileProvider uses ScriptProperty for on-demand data loading
- **Strategy Pattern**: Merge behaviour configurable per-key via lookup_options
- **Variable Substitution**: Resolution paths use PowerShell expression expansion for dynamic lookups
- **Knockout Pattern**: Items prefixed with `--` are removed from merged results

### Data Flow
`
Datum.yml → New-DatumStructure →  (tree of providers)
                                      ↓
Node + PropertyPath → Resolve-Datum → walks ResolutionPrecedence
                                      ↓
                        For each layer: expand path → lookup value
                                      ↓
                        Merge-Datum (if strategy != MostSpecific)
                                      ↓
                        Data Handlers (if matching pattern found)
                                      ↓
                        Return resolved value
`

## File Organization
`
source/
  datum.psd1              # Module manifest
  datum.psm1              # Root module (empty — ModuleBuilder merges all)
  Classes/                # PowerShell classes
    1.DatumProvider.ps1   # Base provider class
    FileProvider.ps1      # Filesystem provider
    Node.ps1              # Node class extending Hashtable
  Public/                 # Exported functions (14 functions)
  Private/                # Internal functions (10 functions)
  ScriptsToProcess/       # Scripts loaded at module import
    Resolve-NodeProperty.ps1  # Global function for DSC integration
  en-US/                  # Localization strings
`

## Testing Architecture

### Test Organization
```
tests/
  Integration/           # All functional tests (Pester 5 syntax)
    assets/              # 7 test data hierarchies
      Demo1/             # Simple 2-layer override demo
      Demo2/             # Node-relative path demo
      Demo3/             # Multi-node role test (Node1/Node2/Node3)
      DSC_ConfigData/    # Classic DSC hierarchy (DEV/PROD, Roles, SiteData)
      DscWorkshopConfigData/  # Full DscWorkshop-style data with encrypted credentials
      MergeTestData/     # Comprehensive merge strategy tests (3 nodes, locations, roles)
      MergeTestDataWithInvokCommandHandler/  # Same as above but with InvokeCommand handler
    Merge.tests.ps1      # Array/hashtable merge strategies (count & value verification)
    Override.tests.ps1   # MostSpecific override behavior (property path resolution)
    Rsop.tests.ps1       # RSOP generation, source tracking, cache cmdlets
    RsopProtectedDatum.tests.ps1  # Credential handling (Datum.ProtectedData handler)
    RsopWithInvokCommandHandler.tests.ps1  # InvokeCommand handler in RSOP context
    Demo3.tests.ps1      # Simple role/disk merge + $false value handling
    Copy-Object.tests.ps1  # Deep copy of FileInfo/DirectoryInfo objects
    Expand-RsopHashtable.tests.ps1  # RSOP hashtable expansion + source info
    Get-RsopValueString.tests.ps1  # RSOP value formatting with source annotations
  QA/                    # Quality assurance tests (module quality, changelog)
```

### Test Patterns
- **Pester 5 syntax**: All tests use `BeforeDiscovery`/`BeforeAll`/`It -ForEach` pattern
- **Data-driven**: Test cases defined as hashtable arrays with node/path/expected values
- **InModuleScope**: Private functions tested via `InModuleScope -ModuleName Datum`
- **Real hierarchies**: Tests use actual Datum.yml + YAML data files, not mocks
- **RSOP output**: Tests write resolved RSOP to `output/RSOP/` and `output/RsopWithSource/` as YAML
- **Module reload**: Tests explicitly `Remove-Module`/`Import-Module` to ensure clean state
- **ScriptBlock evaluation**: Complex property paths use `[scriptblock]::Create("$rsop.$PropertyPath")`

### Test Data Nodes
- **MergeTestData**: DSCFile01, DSCWeb01, DSCWeb02 — tests merge across Roles + Locations
- **DSC_ConfigData**: DEV environment nodes — tests override resolution with environment context
- **DscWorkshopConfigData**: Full hierarchy with ProtectedData credentials + domain join
- **Demo3**: Node1, Node2, Node3 — simple role merge + `$false` value test

### Known Skipped Tests (3 tests)
All in `RsopWithInvokCommandHandler.tests.ps1`, tagged with "There is a bug in the merge logic":
- Ethernet 3 Gateway for DSCFile01
- Ethernet 3 DnsServer for DSCFile01
- Interface Count for DSCFile01

## Build System
- **Sampler-based**: Uses the Sampler module for build/test/publish pipeline
- **ModuleBuilder**: Merges source files into single module output
- **Pester 5**: Integration tests in `tests/Integration/`
- **Azure Pipelines**: CI/CD via `azure-pipelines.yml`
- **GitVersion**: Semantic versioning from git history
- **Build command**: `Start-Process pwsh -ArgumentList '-NoProfile', '-File', 'build.ps1'` (run in separate process to avoid VS Code hanging)
- **Current version**: 0.41.0-docs0001
- **16 build tasks**: Clean → Build_Module → Build_NestedModules → Create_changelog → Pester tests → Coverage check
