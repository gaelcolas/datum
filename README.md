# Datum

[![Build status](https://ci.appveyor.com/api/projects/status/twbfc16g6w68ub8m/branch/master?svg=true)](https://ci.appveyor.com/project/gaelcolas/datum/branch/master)

> `A datum is a piece of information.`

A Sample repository of an Infrastructure from code managed using Datum is available at [**DscInfraSample**](https://github.com/gaelcolas/DscInfraSample), along with more explanations of its usage and the recommended Control repository layout.

## What is Datum for?

This PowerShell Module enables you to manage your **Infrastructure _from_ Code** using **Desired State Configuration** (DSC), by letting you organise the **Configuration Data** in a hierarchy relevant to your environment, and injecting it into **Configurations** based on the Nodes and their Roles.

This (opinionated) approach allows to raise **cattle** instead of pets, while facilitating the management of Configuration Data (the Policy for your infrastructure) and provide defaults with the flexibility of specific overrides per layers based on your environment.

The Configuration Data is composed in a configurable hiearchy, where the storage can be done in files, and the format Yaml, Json, PSD1.

The ideas follows the model developped by the Puppet, Chef and Ansible communities (possibly others), in the following projects:
- [Puppet Hiera](https://puppet.com/docs/puppet/5.3/hiera_intro.html) and [Role and Profiles method](https://puppet.com/docs/pe/2017.3/managing_nodes/the_roles_and_profiles_method.html) (very similar in principle, as I used their great documentation for inspiration, thanks Glenn S. for the pointers!)
- [Chef Databags, Roles and attributes](https://docs.chef.io/policy.html) (thanks Steve for taking the time to explain!)
- [Ansible Playbook](http://docs.ansible.com/ansible/latest/playbooks_intro.html) and [Roles](http://docs.ansible.com/ansible/latest/playbooks_reuse_roles.html) (Thanks Trond H. for the introduction!)

Although not in v1 yet, Datum is currently used in a Production system to manage several hundreds of machines, and is actively maintained.

## Usage


### _Policy for Role 'WindowsBase'_
```Yaml
# WindowsBase.yml
Configurations: #Configurations to Include for Nodes of this role
  - Shared1
  - SoftwareBase
  - Packages

Shared1: # Parameters for Configuration Shared1
  DestinationPath: C:\MyRoleParam.txt
  Param1: This is the Role Value!

SoftwareBase: # Parameters for Configuration SoftwareBase
  Sources:
    - Name: chocolatey
      Disabled: false
      Source: https://chocolatey.org/api/v2

  Packages:
    - Name: chocolatey
    - Name: NotepadPlusplus
      Version: '7.5.2'
    - Name: Putty
```

### _Node Specific data_

```yaml
# SRV01.yml
NodeName: 9d8cc603-5c6f-4f6d-a54a-466a6180b589
role: WindowsBase
Location: LON

```
### Excerpt of DSC Composite Resource (aka. Configuration)

```PowerShell
Configuration SoftwareBase {
    Param(
        $PackageFeedUrl = 'https://chocolatey.org/api/v2',
        $Sources = @(),
        $Packages
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName Chocolatey -ModuleVersion 0.0.46
    
    ChocolateySoftware ChocoInstall {
        Ensure = 'Present'
        PackageFeedUrl = $PackageFeedUrl
    }

    foreach($source in $Sources) {
        if(!$source.Ensure) { $source.add('Ensure', 'Present') }
        Get-DscSplattedResource -ResourceName ChocolateySource -ExecutionName "$($Source.Name)_src" -Properties $source
    }

    foreach ($Package in $Packages) {
        if(!$Package.Ensure) { $Package.add('Ensure','Present') }
        if(!$Package.Version) { $Package.add('version', 'latest') }
        Get-DscSplattedResource -ResourceName ChocolateyPackage -ExecutionName "$($Package.Name)_pkg" -Properties $Properties
    }
}
```

### Root Configuration

```PowerShell
# RootConfiguration.ps1
configuration "RootConfiguration"
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharedDscConfig -ModuleVersion 0.0.3
    Import-DscResource -ModuleName Chocolatey -ModuleVersion 0.0.46

    node $ConfigurationData.AllNodes.NodeName {
        (Lookup $Node 'Configurations') | % {
            $ConfigurationName = $_
            $Properties = $(lookup $Node $ConfigurationName -Verbose -DefaultValue @{})
            x $ConfigurationName $ConfigurationName $Properties
        }
        #>
    }
}

RootConfiguration -ConfigurationData $ConfigurationData -Out "$BuildRoot\BuildOutput\MOF\"

```

## Under the hood

It does so by abstracting the underlying storage (i.e. files in folders) and format (json, yaml, PSD1), and representing the data as a structured object, walkable using the '.' notation: 

_i.e._ `$object.property1.subproperty2`

There is potential for this tool to be used outside DSC, so an effort is made to abstract the DSC Specifics as long as possible.

The goal is to be able to assemble providers, so that the Datum structure can be composed with different technologies.
For instance, one could compose like so:
 - Local File Credential stores
 - Secret Vault
 - Database Data
 - File Data


## History
Back in 2014, Steve Murawski then working for Stack Exchange lead the way by implementing some tooling, and open sourced them on the [PowerShell.Org's Github](https://github.com/PowerShellOrg/DSC/tree/development).
This work has been complemented by Dave Wyatt's contribution mainly around the Credential store.
After these two main contributors moved on from DSC and Pull Server mode, the project stalled (in the Dev branch), despite its unique value.

I [refreshed this](https://github.com/gaelcolas/DscConfigurationData) to be more geared for PowerShell 5, and updated the dependencies as some projects had evolved and moved to different maintainers, locations, and name.

As I was re-writing it, I found that the version offered a very good way to manage configuration data, but in a prescriptive way, lacking a bit of flexibility for some much needed customisation (layers and ordering). Steve also pointed me to [Chef's Databag](https://docs.chef.io/data_bags.html), and later I discovered [Puppet's Hiera](https://docs.puppet.com/hiera/3.3/complete_example.html), which is where I get most of my inspiration.