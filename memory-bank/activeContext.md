# Active Context

## Current State (as of 2026-02-23)
The project is on the `feature/docs` branch (tracking `main`). Recent work has focused on **documentation quality** — auditing and fixing code samples in all docs, and correcting the `-IncludeSource`/`-RemoveSource` documentation for `Get-DatumRsop`.

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

## Recent Changes (Last Commits)
- `99debf7` — Updating readme video
- `b437d86` — Pester v4 to v5 migration for all tests
- `96c4aac` — Merge-DatumArray: Convert tuple key values to datum before merging
- `8229245` — Added more tests for hash table merging with datum handlers
- `bbf4589` — Updated build scripts to Sampler 0.119.0-preview0005
- `baa5626` — Reworked knockout code to consider hierarchy
- `cad76e3` — Added cleanup of knockout items

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
