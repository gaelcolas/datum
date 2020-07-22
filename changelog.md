# Changelog

## Unreleased

### Changed

- Corrected a typo and incorrect debug information

### Fixed

- Fixed issue in Merge-DatumArray where it used ArrayList.AddRange to add hashtables (each key/value pair is added as a new object),
  where Add should have been used (each hashtable is a new object).

## [0.0.38]

### Fixed

- Datum on linux (change case on Datum.psd1 and Datum.psm1)

## [0.0.37]

### Fixed

- Datum in PSCore 6 on Windows (Write-Output -NoEnumerate bug)

## [0.0.36]

### Removed

- [breaking] Get-DscSplattedResource script to process is removed and now available in the DscBuildHelpers module (Datum is not DSC specific, now it's fully decoupled)

### Fixed

- fixed issue with merging arrays of hashtables

## [0.0.35]

### Removed

- ProtectedData / Data Encryption datum handler is no longer built-in (need external module `Datum.ProtectedData` available in the gallery)

### Added

- PowerShell 6 (aka Core) support. By dropping the ProtectedData dependency, Datum now works on PSCore.

### Fixed

- Allowing to set the CompositionKey of the `Get-DatumRSOP` command