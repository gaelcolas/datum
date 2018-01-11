# Datum

[![Build status](https://ci.appveyor.com/api/projects/status/twbfc16g6w68ub8m/branch/master?svg=true)](https://ci.appveyor.com/project/gaelcolas/datum/branch/master)

> `A datum is a piece of information.`

**Datum** is a PowerShell module to lookup **configuration data** from aggregated sources allowing you to define generic information (Roles) and specific overrides (i.e. per Node, Location, Environment) without repeating yourself.

A Sample repository of an ['Infrastructure _as_ code'](https://devopscollective.org/maybe-infrastructure-as-code-isnt-the-right-way/) managed using Datum is available at [**DscInfraSample**](https://github.com/gaelcolas/DscInfraSample), along with more explanations of its usage and the recommended Control repository layout.

Datum currently works on Windows PowerShell 5.1, as it relies on specific dlls and Module (ProtectedData) for **Credential and Data Encryption**. These functionalities will soon be moved to an optional module (code already decoupled).

## What is Datum for?

This PowerShell Module enables you to manage your **Infrastructure _from_ Code** using **Desired State Configuration** (DSC), by letting you organise the **Configuration Data** in a hierarchy relevant to your environment, and injecting it into **Configurations** based on the Nodes and their Roles.

This (opinionated) approach allows to raise **cattle** instead of pets, while facilitating the management of Configuration Data (the Policy for your infrastructure) and provide defaults with the flexibility of specific overrides per layers based on your environment.

The Configuration Data is composed in a configurable hiearchy, where the storage can be done in files, and the format Yaml, Json, PSD1.

The idea follows the model developped by the Puppet, Chef and Ansible communities (possibly others), in the configuration data management area:
- [Puppet Hiera](https://puppet.com/docs/puppet/5.3/hiera_intro.html) and [Role and Profiles method](https://puppet.com/docs/pe/2017.3/managing_nodes/the_roles_and_profiles_method.html) (very similar in principle, as I used their great documentation for inspiration, thanks Glenn S. for the pointers!)
- [Chef Databags, Roles and attributes](https://docs.chef.io/policy.html) (thanks Steve for taking the time to explain!)
- [Ansible Playbook](http://docs.ansible.com/ansible/latest/playbooks_intro.html) and [Roles](http://docs.ansible.com/ansible/latest/playbooks_reuse_roles.html) (Thanks Trond H. for the introduction!)

Although not in v1 yet, Datum is currently used in a Production to manage several hundreds of machines, and is actively maintained.

## Intended Usage

The overall goal, better covered in the book [Infrastructure As Code](http://infrastructure-as-code.com/book/) by Kief Morris, is to enable a team to "_quickly, easily, and confidently adapt their infrastructure to meet the changing needs of their organization_".

To do so, we define our Infrastructure with as a set of Policies: human-readable documents describing the intended result (or Desired State), in structured, declarative aggregation of data, that are also usable by computers.

We then interpret and transform the data to pass it over to the platform and technology components grouped in manageable units.

Finally, the decentralised execution can converge towards the policy by executing a set of atomic actions deducted from the required changes specific to each technology.

The policies and their execution are composed in layers of abstraction, so that people with different responsibilities, specialisations and accountabilites have access to the right amount of data in the layer they operate for their task.


### _Policy for Role 'WindowsServerDefault'_

At a high level, we can compose a Role that should apply for a set of nodes, with what we'd like to see configured.

In this document, we define a default role we intend for generic Windows Servers, and include the different Configurations we need (Shared1,SoftwareBaseline). Those

We then provide the data for the parameters to those configurations.

```Yaml
# WindowsServerDefault.yml
Configurations: #Configurations to Include for Nodes of this role
  - Shared1
  - SoftwareBaseline

Shared1: # Parameters for Configuration Shared1
  DestinationPath: C:\MyRoleParam.txt
  Param1: This is the Role Value!

SoftwareBaseline: # Parameters for DSC Composite Configuration SoftwareBaseline
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
The baseline for this role is self documenting. This SoftwareBaseline is specific data for that role, and can be different for another role, while the underlying code would not change.
Adding a new package is trivial and does not need any DSC or Chocolatey knowledge.

### _Node Specific data_

We define the nodes with the least amount of uniqueness, to avoid snowflakes.
Below, we only say where the Node is located, what role is associated to it, its name (SRV01, the file's BaseName) and a unique identifier.

```yaml
# SRV01.yml
NodeName: 9d8cc603-5c6f-4f6d-a54a-466a6180b589
role: WindowsServerDefault
Location: LON

```

### _Excerpt of DSC Composite Resource (aka. Configuration)_

This is where the Configuration Data is massaged in usable ways for the underlying technologies (DSC resources).

Here we are creating a SoftwareBaseline by:
- Installing Chocolatey from a Nuget Feed (using the Resource ChocolateySoftware)
- Registering a Set of Sources provided from the Configuration Data
- Installing a Set of packages as per the Configuration data

```PowerShell
Configuration SoftwareBaseline {
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
In this configuration example, Systems Administrators do not need to be Chocolatey Software specialists to know how to create a Software baseline using the Chocolatey DSC Resources.


### _Root Configuration_

Finally the root configuration is where each node is processed.

We import the Module or DSC Resources needed by the Configurations, and for each Node, we lookup the Configurations included by the policies, and for each of those we lookup for the parameters and splat them to the DSC Resources.

**This file does not need to change, it is Dynamic!**

```PowerShell
# RootConfiguration.ps1
configuration "RootConfiguration"
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharedDscConfig -ModuleVersion 0.0.3
    Import-DscResource -ModuleName Chocolatey -ModuleVersion 0.0.46

    node $ConfigurationData.AllNodes.NodeName {
        (Lookup 'Configurations').Foreach{
            $ConfigurationName = $_
            $Properties = $(lookup $ConfigurationName -DefaultValue @{})
            Get-DscSplattedResource -ResourceName $ConfigurationName -ExecutionName $ConfigurationName -Properties $Properties
        }
    }
}

RootConfiguration -ConfigurationData $ConfigurationData -Out "$BuildRoot\BuildOutput\MOF\"

```

## Under the hood

Although Datum has been primarily targeted at DSC Configuration Data, it can be used in other context where the hierachical model and lookup makes sense.

### Building a Datum Hierarchy

The Datum hierarchy, similar to Puppet and Hiera, is defined typically in a [**Datum.yml**](.\Datum\tests\Integration\assets\DSC_ConfigData\Datum.yml) at the base of the Config Data files.
Although Datum comes only with a built-in _Datum File Provider_ (Not SHIPS) supporting the **JSON, Yaml, and PSD1** format, it can call external PowerShell modules implementing the Provider functionalities.


#### Root Branches

A branch of the Datum Tree would be defined within the DatumStructure of the Datum.yml like so:

```yaml
# Datum.yml
DatumStructure:
  - StoreName: AllNodes
    StoreProvider: Datum::File
    StoreOptions:
      Path: "./AllNodes"
```
Instanciating a variable from that definition would be done with this:
> `$Datum = New-DatumStructure -DefinitionFile Datum.yml`

This returns a hashtable with a key 'AllNodes' (StoreName), by using the internal command (under the hood):
> `Datum\New-DatumFileProvider -Path "./AllNodes"`

Should you create a module (e.g. named 'MyReddis'), implementing the function `New-DatumReddisProvider` you could write the following _Datum.yml_ to use it (as long as it's in your **PSModulePath**):
```yaml
# Datum.yml
DatumStructure:
  - StoreName: AllNodes
    StoreProvider: MyReddis::Reddis
    StoreOptions:
      YourParameter: ParameterValue
```
If you do, please let me know I'm interested :)

You can have several **root branches**, of different **_Datum Store Providers_**, with custom options (but prefer to Keep it super simple).

#### Store Provider

So what should those store providers look like? What do they do?

In short, they abstract the underlying data storage and format, in a way that will allow us to consistently do **key/value lookups**.

The main reason(s) it is not based on SHIPS (or @Beefarino's Simplex module, which I tried and enjoyed!), is that the PowerShell Providers did not seem to provide enough abstraction for read-only key/value pair access. These are still very useful (and used) as an intermediary abstraction, such as the FileSystem provider used [here](./Datum/Classes/FileProvider.ps1).

In short I wanted an uniform key, that could abstract the container, the store, and the structure within the Format.
Imagine the standard FileSystem provider:

> Directory > File > PSD1

Where the file `SERVER01.PSD1` is in the folder `.\AllNodes\`, and has the following data:
```PowerShell
# SERVER01.PSD1
@{
    Name = 'SERVER01'
    MetaData = @{
        Subkey = 'Data Value'
    }
}
```
I wanted that the key 'AllNodes\SERVER01\MetaData\Subkey' returns '`Data Value`'.

However, while the notation with Path Separator (`\`) is used for **lookups** (more on this later), the provider abstracts the storage+format using the **dot notation**.

From the example above where we loaded our Datum Tree, we'd use the following to return the value:
> `$Datum.AllNodes.SERVER01.MetaData.Subkey`

So we're just accessing variable properties, and our Config Data stored on the FileSystem, in case of the FileProvider, is just _mounted_ in a variable.

With the **dot notation** we have access using asbolute keys to all values via the root `$datum`, but this is not much different from having all data in one big hashtable or PSD1 file...

### Lookups and overrides in Hierarchy

We can mount different _Datum Stores_ (unit of Provider + Parameters) as branches onto our `root` variable.
Typically, I mount the following structure (with many more files not listed here):
```
DSC_ConfigData
│   Datum.yml
├───AllNodes
│   ├───DEV
│   └───PROD
├───Environments
├───Roles
└───SiteData
```
I can access the data with:
> `$Datum.AllNodes.DEV.SRV01`

or
> `$Datum.SiteData.London`

But to be a hierarchy, there should be an order of precedence, and the `lookup` is a function that resolves a **relative path**, in the paths defined by the order of precedence.


_(To be Continued)_

------

## History
Back in 2014, Steve Murawski then working for Stack Exchange lead the way by implementing some tooling, and open sourced them on the [PowerShell.Org's Github](https://github.com/PowerShellOrg/DSC/tree/development).
This work has been complemented by Dave Wyatt's contribution mainly around the Credential store.
After these two main contributors moved on from DSC and Pull Server mode, the project stalled (in the Dev branch), despite its unique value.

I [refreshed this](https://github.com/gaelcolas/DscConfigurationData) to be more geared for PowerShell 5, and updated the dependencies as some projects had evolved and moved to different maintainers, locations, and name.

As I was re-writing it, I found that the version offered a very good way to manage configuration data, but in a prescriptive way, lacking a bit of flexibility for some much needed customisation (layers and ordering). Steve also pointed me to [Chef's Databag](https://docs.chef.io/data_bags.html), and later I discovered [Puppet's Hiera](https://docs.puppet.com/hiera/3.3/complete_example.html), which is where I get most of my inspiration.