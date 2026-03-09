# Project Brief: Datum

## Overview
**Datum** is a PowerShell module for aggregating **DSC (Desired State Configuration) configuration data** from multiple hierarchical sources. It enables policy-driven infrastructure management by organizing configuration data in customizable layers with override capabilities.

## Core Purpose
Enable teams to manage infrastructure as code by defining generic policies (Roles) with specific overrides (per Node, Location, Environment) — following the DRY (Don't Repeat Yourself) principle for DSC configuration data.

## Key Goals
- **Hierarchical data management**: Organize configuration data in layers (Nodes > Environments > Locations > Roles) with configurable precedence
- **Flexible data merging**: Support multiple merge strategies (MostSpecific, MergeTopKeys, MergeRecursively) for combining data across layers
- **Multiple format support**: Read configuration from YAML, JSON, and PSD1 files
- **Extensible providers**: Built-in FileProvider with extensible store provider architecture
- **Data handlers**: Support external handlers for encrypted credentials (Datum.ProtectedData) and dynamic expressions (Datum.InvokeCommand)
- **PowerShell 7 compatible**: Works on PowerShell 7 (PSCore)

## Author & Organization
- **Author**: Gael Colas (gaelcolas)
- **Company**: SynEdgy Limited
- **License**: MIT (see LICENSE)
- **Repository**: https://github.com/gaelcolas/Datum/
- **Gallery**: Published to PowerShell Gallery

## Inspiration
Modeled after similar configuration data management tools:
- Puppet Hiera (primary inspiration)
- Chef Databags/Roles
- Ansible Playbooks/Roles

## Current Version
- Latest release: v0.40.1 (April 2023)
- Active development on main branch with unreleased features (knockout support, Pester 5 migration)
