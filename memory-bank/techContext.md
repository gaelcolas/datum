# Technical Context

## Technology Stack
- **Language**: PowerShell 5.1+ / PowerShell 7 (PSCore)
- **Module Type**: Script module with classes (PSM1 + PSD1)
- **Data Formats**: YAML (primary), JSON, PSD1
- **Build System**: Sampler (InvokeBuild-based)
- **Testing**: Pester 5
- **CI/CD**: Azure DevOps Pipelines
- **Versioning**: GitVersion (Semantic Versioning)
- **Package Distribution**: PowerShell Gallery

## Dependencies
### Runtime
- `powershell-yaml` — YAML parsing (required module)

### Optional/External
- `Datum.ProtectedData` — Handler for encrypted credentials
- `Datum.InvokeCommand` — Handler for dynamic expression evaluation
- `ProtectedData` — Underlying encryption module (used by Datum.ProtectedData)

### Build/Dev
- `InvokeBuild` — Task runner
- `ModuleBuilder` — Module compilation
- `Sampler` + `Sampler.GitHubTasks` — Build pipeline framework
- `Pester` — Testing framework (v5)
- `PSScriptAnalyzer` — Code analysis
- `DscResource.Test` + `DscResource.AnalyzerRules` — DSC-specific testing
- `ChangelogManagement` — Changelog management
- `Plaster` — Template scaffolding

## Development Setup
1. Clone the repository
2. Run `.\Resolve-Dependency.ps1` to install build dependencies to `output/RequiredModules/`
3. Run `.\build.ps1 -AutoRestore` for full build
4. Run `.\build.ps1 -AutoRestore -Tasks test` to run tests
5. Built module output goes to `output/datum/<version>/`

## Key Technical Decisions
- **ModuleBuilder compilation**: Source files are merged into a single PSM1 at build time (source/datum.psm1 is essentially empty)
- **Class loading order**: `1.DatumProvider.ps1` is numbered to ensure it loads before `FileProvider.ps1` (which inherits from it)
- **Global function**: `Resolve-NodeProperty` is defined as `Global:` scope function via ScriptsToProcess — required for DSC compilation context
- **Lazy ScriptProperty**: FileProvider creates ScriptProperty members to avoid loading all data files at initialization
- **RSOP caching**: `Get-DatumRsop` caches resolved results in `` for performance

## Technical Constraints
- Must work on both Windows PowerShell 5.1 and PowerShell 7
- No binary dependencies (pure PowerShell)
- External data handler modules are optional, not bundled
- File provider is the only built-in store provider
- PSD1 format does not support ordering (unlike YAML)

## Tool Usage Patterns
- `build.ps1 -AutoRestore` — Build with automatic dependency resolution
- `build.ps1 -AutoRestore -Tasks test` — Run Pester tests
- `build.ps1 -AutoRestore -Tasks pack` — Build + package as NuGet
- Output structure: `output/datum/<version>/datum.psd1`, `datum.psm1`
