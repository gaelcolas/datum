# Active Context

## Current State (as of 2026-03-07)
The project is on the `feature/docs` branch. Recent work has focused on adding support for **conditional ResolutionPrecedence entries** using `Datum.InvokeCommand` expressions.

## Current Work Focus
The project has **unreleased changes** (tracked in CHANGELOG.md under [Unreleased]) that include:

### Unreleased Features & Fixes
1. **Conditional ResolutionPrecedence entries** — `Resolve-Datum` now filters out null/empty/whitespace path prefixes after datum handler invocation, enabling conditional `[x= ... =]` expressions in `ResolutionPrecedence` that can return nothing for certain nodes.
2. **Integration test for conditional precedence** — Added InvokeCommand expression to test `Datum.yml` that conditionally includes a path only for non-file-server nodes.
3. **SkipReason removal** — Removed `SkipReason` from RSOP test cases due to resolved merge logic bug.

## Recent Changes (Last Session)
- Added `Where-Object { -not [string]::IsNullOrWhiteSpace($_) }` filter in `Resolve-Datum.ps1` after `ConvertTo-Datum` handler processing of `$PathPrefixes`
- Added conditional InvokeCommand expression to `tests/Integration/assets/DscWorkshopConfigData/Datum.yml`
- Updated CHANGELOG.md with Added and Changed entries under [Unreleased]
- Added "Conditional Entries with InvokeCommand" section to `docs/DatumYml.md`
- Added PathPrefixes filtering note to `docs/CmdletReference.md`

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
