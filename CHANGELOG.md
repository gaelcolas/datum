# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added support for specifying the encoding (#87).

### Fixed

- Fixed how issue not allowing Datum handlers to be used on arrays (#89).
- Fixed issue in Merge-Hashtable where it did not merge hashtables correctly when these
  are included in an array.

## [0.0.39] - 2020-09-29

### Added

- Corrected a typo and incorrect debug information.
- New CI process.

### Changed

- Updated new build.ps1 from sampler.

### Fixed

- Fixed issue in Merge-DatumArray where it used ArrayList.AddRange to add hashtables (each key/value pair 
  is added as a new object), where Add should have been used (each hashtable is a new object).

## [0.0.38] - 2019-03-31

### Fixed

- Datum on linux (change case on Datum.psd1 and Datum.psm1)

## [0.0.37] - 2019-03-31

### Fixed

- Datum in PSCore 6 on Windows (Write-Output -NoEnumerate bug)

## [0.0.36] - 2019-01-22

### Removed

- [breaking] Get-DscSplattedResource script to process is removed and now available in the DscBuildHelpers module (Datum is not DSC specific, now it's fully decoupled)

### Fixed

- fixed issue with merging arrays of hashtables

## [0.0.35] - 2018-11-19

### Removed

- ProtectedData / Data Encryption datum handler is no longer built-in (need external module `Datum.ProtectedData` available in the gallery)

### Added

- PowerShell 6 (aka Core) support. By dropping the ProtectedData dependency, Datum now works on PSCore.

### Fixed

- Allowing to set the CompositionKey of the `Get-DatumRSOP` command
