# Active Context

## Current State (as of 2026-02-25)
The project is on the `main` branch. Recent work has focused on **PR #154 improvements** — making the `ConvertFrom-Yaml` consolidation for JSON files more comprehensive with proper CHANGELOG categorization and integration tests for JSON/YAML equivalence.

## Current Work Focus
The project has **unreleased changes** (tracked in CHANGELOG.md under [Unreleased]) that include:

### Unreleased Features & Fixes
1. **Knockout support for basetype arrays** — New feature allowing items to be removed from inherited arrays
2. **Cleanup of knockout items** — Post-merge cleanup of knockout markers
3. **Pester tests for credential handling** — New test coverage
4. **ConvertTo-Datum fix** — Fixed returning `` when DatumHandler returns `False` (#139)
5. **Merge-DatumArray fix** — Fixed not returning array when merged array contains single hashtable
6. **Hashtable array merge fix** — Fixed items not merging when using datum handler for tuple keys (#155)
7. **Copy-Object fixes** — Fixed and extended tests, PowerShell 7 compatibility
8. **Pester 5 migration** — All integration tests migrated to Pester 5 syntax
9. **Build system update** — Updated to Sampler 0.119.0-preview0005
10. **Merge-DatumArray improvement** — Convert tuple key values to datum before merging

## Recent Changes (Last Session)
- Moved CHANGELOG entry for PR #154 from `Added` to `Changed` with expanded description and PR link
- Created `tests/Integration/GetFileProviderData.tests.ps1` — 33 new tests for JSON/YAML equivalence
- Created test data in `tests/Integration/assets/JsonYamlEquivalence/` (JSON + YAML pairs)
- **Build result**: 191 passed, 0 failed, 3 skipped (pre-existing)

## Next Steps
- ~~**Fix Issue #136**~~: DONE — depth now configurable via `default_json_depth` in Datum.yml (default 4), 8 tests, zero truncation warnings. Build verified, all tests passing. Ready for PR.
- Release the accumulated unreleased changes as a new version
- Fix the merge logic bug causing 3 skipped tests (Ethernet 3 Gateway/DnsServer/InterfaceCount for DSCFile01 in InvokeCommand handler context)
- Consider additional test coverage for knockout scenarios
- Enable code coverage (currently threshold = 0)
- Consider making `-IncludeSource` and `-RemoveSource` mutually exclusive at the parameter level (ValidateScript or ParameterSets) rather than silent precedence

## Active Decisions
- All tests now use Pester 5 syntax (migration complete)
- Knockout prefix is `--` (consistent with Puppet Hiera convention)
- Build system uses Sampler framework (recently updated to 0.119.1)
- Build must be run in separate process to avoid VS Code hanging

## Important Patterns
- When modifying merge logic, ensure both hashtable and array paths are tested
- Data handler invocation must be tested with both `False` and `` returns
- Copy-Object must work identically on PS 5.1 and PS 7
- Tests use `BeforeDiscovery` for test case generation and `BeforeAll` for module setup
- Private functions are tested via `InModuleScope -ModuleName Datum`
- RSOP tests output resolved YAML files to `output/RSOP/` and `output/RsopWithSource/`
- ProtectedData handler errors are expected in tests (wrong encryption key = graceful fallback)
- `-IncludeSource` and `-RemoveSource` are mutually exclusive — `if/elseif` branching means `-IncludeSource` always wins when both are specified
- Source tracking uses `__File` NoteProperties on values (not `__source` hashtable keys); `-IncludeSource` renders these as right-aligned inline annotations via `Get-RsopValueString`
- AllNodes iteration code must handle both flat and nested directory layouts (docs now show both patterns)
