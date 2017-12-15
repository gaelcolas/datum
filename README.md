# Datum

[![Build status](https://ci.appveyor.com/api/projects/status/twbfc16g6w68ub8m/branch/master?svg=true)](https://ci.appveyor.com/project/gaelcolas/datum/branch/master)

`A datum is a piece of information.`

This project is an attempt at managing hierarchical configuration data for Desired State Configuration (DSC).


It does so by abstracting the underlying storage (i.e. files in folders) and format (json, yaml, PSD1), and representing the data as a structured object, walkable using the '.' notation: 

_i.e._ `$object.property1.subproperty2`

There is potential for this tool to be used outside DSC, so an effort is made to abstract the DSC Specifics as long as possible.

The goal is to be able to assemble providers, so that the Datum structure can be composed with different technologies.
For instance, one could compose like so:
 - Local File Credential stores
 - Secret Vault
 - Database Data
 - File Data

## Usage

For now, this is only a prototype, and the best documentation is the Demo:
- [Datum Structure](./Datum/examples/demo1/datum.yml) by combining provider
- [example file](./Datum/examples/demo1/demo1.ps1) that loads structure and execute some search in different modes
- [the root](./Datum/examples/demo1/DSC_Configuration) of the config data

```PowerShell
Resolve-Datum -searchPaths $yml.ResolutionPrecedence `
              -DatumStructure $datum `
              -PropertyPath 'ExampleProperty1' `
              -SearchBehavior 'AllValues'

#Searching all Properties 'ExampleProperty1' for FileServer01:
#From Node
#From Site
#From All SiteData
#From Role
#From All Roles
```

## TODO

- Features / Roadmap
    - [x] FileSystem Provider
    - [x] Yaml, JSON, PSD1 Formats
    - [x] Hierachical data with order of precedence
    - [x] Throw exception when a Value is null
    - [x] Allow Default value (like Invoke-BUild's property)
    - [x] Credentials/Encrypted data via Protected-Data
    - [ ] Merge behaviour of the datum when type is hashtable/Array

## Lack of Tooling around DSC

DSC Being a platform, it does not come bundled with tooling to manage a deployed scenario, so customisations must be provided.

In DSC, the examples of Configuration Data always refer to a very simple structure for explaining the concepts simply.
For instance, [one of Nana's post on the subject](https://blogs.msdn.microsoft.com/powershell/2014/01/09/separating-what-from-where-in-powershell-dsc/) shows the following:
```
# Content of configuration data file (e.g. ConfigurationData.psd1) could be:
 
# Hashtable to define the environmental data
@{
    # Node specific data
    AllNodes = @(
 
       # All the WebServer has following identical information
       @{
            NodeName           = “*”
            WebsiteName        = “FourthCoffee”
            SourcePath         = “C:\BakeryWebsite\”
            DestinationPath    = “C:\inetpub\FourthCoffee”
            DefaultWebSitePath = “C:\inetpub\wwwroot”
       },
 
       @{
            NodeName           = “WebServer1.fourthcoffee.com”
            Role               = “Web”
        },
 
       @{
            NodeName           = “WebServer2.fourthcoffee.com”
            Role               = “Web”
        }
    );
}
```

In practice, using a single flat file is not scalable or defining within the script, and generating the data structure dynamically can pose some conceptual problem about [Policy-driven infrastructure](http://devopscollective.org/maybe-infrastructure-as-code-isnt-the-right-way/).
- Less visible policy
- Added complexity by managing configuration and data separetely
- added overhead for managing the changes (instead of git with build pipeline)
- less portable ...

## History
Back in 2014, Steve Murawski then working for Stack Exchange lead the way by implementing some tooling, and open sourced them on the [PowerShell.Org's Github](https://github.com/PowerShellOrg/DSC/tree/development).
This work has been complemented by Dave Wyatt's contribution mainly around the Credential store.
After these two main contributors moved on from DSC and Pull Server mode, the project stalled (in the Dev branch), despite its unique value.

I [refreshed this](https://github.com/gaelcolas/DscConfigurationData) to be more geared for PowerShell 5, and updated the dependencies as project had evolved and moved to different maintainer, locations, and name.

As I was re-writing it, I found that the version offered a very good way to manage configuration data, but in a prescriptive way, lacking a bit of flexibility for some customisation. Steve also pointed me to [Chef's Databag](https://docs.chef.io/data_bags.html), and later I discovered [Puppet's Hiera](https://docs.puppet.com/hiera/3.3/complete_example.html), which is where I get most of my inspiration.