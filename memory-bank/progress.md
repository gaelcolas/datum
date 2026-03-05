# Progress

## What Works (Stable Features)
- **Core hierarchy resolution**: `New-DatumStructure`, `Resolve-Datum`, `Resolve-NodeProperty`
- **File provider**: Filesystem-based data store with YAML, JSON, PSD1 support
- **Merge strategies**: MostSpecific, hash (MergeTopKeys), deep (MergeRecursively)
- **Array merge**: Sum/Add, Unique, DeepTuple (merge by tuple keys), UniqueKeyValTuples
- **Variable substitution**: Dynamic path resolution using Node properties
- **RSOP generation**: `Get-DatumRsop` with caching and source tracking
- **Data handler system**: Extensible handler architecture with regex-based matching
- **Encoding support**: Configurable file encoding (#87)
- **Error handling**: `Get-FileProviderData` with error handling
- **PowerShell 7 support**: Full cross-platform compatibility (PS 5.1 + PS 7)
- **Published to PowerShell Gallery**: Stable v0.40.1 available

## What's Been Recently Completed (Unreleased)
- [x] Knockout support for basetype arrays
- [x] Knockout item cleanup
- [x] Pester 5 migration for all integration tests
- [x] Fix: `ConvertTo-Datum` returning `` for `False` handler results (#139)
- [x] Fix: `Merge-DatumArray` single-hashtable array return
- [x] Fix: Hashtable array items not merging with datum handlers (#155)
- [x] Fix: `Copy-Object` PS7 compatibility
- [x] Build system update to Sampler 0.119.0-preview0005
- [x] Merge-DatumArray: tuple key values converted to datum before merging

## Documentation Improvements (2026-02-23)
- [x] Fixed AllNodes iteration code samples for nested directory layouts (README.md, RSOP.md, AboutDatum.md)
- [x] Fixed `-IncludeSource` output examples (was fake `__source` YAML keys, now shows actual right-aligned annotations)
- [x] Documented `-IncludeSource`/`-RemoveSource` mutual exclusivity and actual behaviour
- [x] Fixed troubleshooting section (removed nonexistent `$rsop.SomeKey.__source` pattern)
- [x] Updated CmdletReference.md parameter descriptions for accuracy

## What's Left to Build / Open Areas
- [ ] Release next version with all unreleased changes
- [ ] Additional store providers beyond FileProvider (community-driven)
- [ ] Performance optimization for large hierarchies
- [ ] Code coverage improvements (threshold currently set to 0 in build.yaml)

## Known Issues
- ~~**GitHub issue #136**~~: FIXED — `ConvertTo-Json` depth now configurable via `default_json_depth` in Datum.yml (default 4). All 5 calls updated. `Invoke-TestHandlerAction` also uses `-WarningAction SilentlyContinue` (serializes entire `$Datum` tree). 8 tests in `tests/Integration/DeepStructure.tests.ps1` (all passing). Zero truncation warnings in full test suite.
- GitHub issue #139: Fixed (unreleased) — `ConvertTo-Datum` null return for `False`
- GitHub issue #155: Fixed (unreleased) — Hashtable array merge with datum handlers
- GitHub issue #87: Fixed in v0.40.1 — Encoding support
- GitHub issue #89: Fixed in v0.40.1 — Datum handlers on arrays
- **Merge logic bug**: 3 Pester tests skipped in RsopWithInvokCommandHandler — Ethernet 3 Gateway, DnsServer, and Interface Count for DSCFile01 fail due to merge logic bug (hashtable array deep merge with InvokeCommand handler)

## Version History
| Version | Date       | Key Changes |
|---------|------------|-------------|
| 0.40.1  | 2023-04-03 | Encoding support, RSOP cache, array handler fix, Merge-Hashtable fix |
| 0.0.39  | 2020-09-29 | New CI, encoding support, ArrayList.AddRange fix |
| 0.0.38  | 2019-03-31 | Linux case-sensitivity fix |
| 0.0.37  | 2019-03-31 | PSCore 6 Windows fix |
| 0.0.36  | 2019-01-22 | Removed Get-DscSplattedResource (moved to DscBuildHelpers), array merge fix |
| 0.0.35  | 2018-11-19 | PS6 support, removed built-in ProtectedData handler |

## Project Health
- **CI**: Azure DevOps Pipelines (build + test)
- **Last build**: 2026-02-25 — **Build succeeded** (all tasks passed, 0 errors, 0 warnings)
- **Test results**: **All passed, 0 failed, 3 skipped** (skipped due to known merge logic bug)
- **Build version**: 0.41.0 (pre-release from feature branch)
- **Test coverage**: Code coverage threshold set to 0 (disabled) in build.yaml
- **ProtectedData warnings**: Expected — test credential encrypted with different key, handler gracefully returns raw string
- **Active maintenance**: Last commit activity on main branch (README updates)
- **Community**: Used in production managing hundreds of machines
- **Build tip**: Run build in separate process (`Start-Process pwsh`) to avoid VS Code hanging
