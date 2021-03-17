# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Corrected a typo and incorrect debug information.
- New CI process.
- Added support for specifying the encoding (#87).
- Added more tests and test data.

### Changed

- Updated new build.ps1 from sampler.

### Fixed

- Fixed issue in Merge-DatumArray where it used ArrayList.AddRange to add hashtables (each key/value pair is added as a new object),
  where Add should have been used (each hashtable is a new object).
- Fixed how issue not allowing Datum handlers to be used on arrays (#89).
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
- Fixed an issue visible in the test log: https://synedgy.visualstudio.com/Datum/_build/results?buildId=633&view=logs&j=14d0eb3f-bc66-5450-3353-28256327ad6c&t=c344f041-83bb-5f7b-1678-8a78f1873256&l=79.
=======
>>>>>>> 3dae1b1 ( Fixes #89)
=======
- Fixed an issue visible in the test log: https://synedgy.visualstudio.com/Datum/_build/results?buildId=633&view=logs&j=14d0eb3f-bc66-5450-3353-28256327ad6c&t=c344f041-83bb-5f7b-1678-8a78f1873256&l=79.
>>>>>>> fc6ab23 (Updated changelog)
=======
- Fixed an issue visible in the test log: https://synedgy.visualstudio.com/Datum/_build/results?buildId=633&view=logs&j=14d0eb3f-bc66-5450-3353-28256327ad6c&t=c344f041-83bb-5f7b-1678-8a78f1873256&l=79.
>>>>>>> c59fadf1109aa6042368c02655085f29733b45f4

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
