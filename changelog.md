# Changelog

## [0.0.35]
### Removed
- ProtectedData / Data Encryption datum handler is no longer built-in (need external module `Datum.ProtectedData` available in the gallery)

### Added
- PowerShell 6 (aka Core) support. By dropping the ProtectedData dependency, Datum now works on PSCore.

### Fixed
- Allowing to set the CompositionKey of the `Get-DatumRSOP` command