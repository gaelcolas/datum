# Datum

[![Build status](https://ci.appveyor.com/api/projects/status/twbfc16g6w68ub8m/branch/master?svg=true)](https://ci.appveyor.com/project/gaelcolas/datum/branch/master) [![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Datum.svg)](https://www.powershellgallery.com/packages/datum)


> `A datum is a piece of information.`

**Datum** is a PowerShell module used to aggregate **DSC configuration data** from multiple sources allowing you to define generic information (Roles) and specific overrides (i.e. per Node, Location, Environment) without repeating yourself.

To see it in action, I recommend looking at the full day workshop (reduced to 3.5 hours) by Raimund Andree and Jan-Hendrick Peters.
The [video recording here](https://livestream.com/gaelcolas/events/8824779/videos/196854817), and the [DSC Workshop repository there](https://github.com/dsccommunity/DscWorkshop/).

Datum is working with PowerShell 7.

A new version is in the works, encouragement welcomed. :)

## Table of Content

 1. [Why Datum?](#1-why-datum)
 2. [Getting Started & Concepts](#2-getting-started-concepts)
    - [Data layers and precedence](#data-layers-and-precedence)
    - [Path relative to $Node](#path-relative-to-node)
 3. [Intended Usage](#3-intended-usage)
    - [Policy for Role 'WindowsServerDefault'](#policy-for-role-windowsserverdefault)
    - [Node Specific data](#node-specific-data)
    - [Excerpt of DSC Composite Resource (aka. Configuration)](#excerpt-of-dsc-composite-resource-aka-configuration)
    - [Root Configuration](#root-configuration)
 4. [Under the hood](#4-under-the-hood)
    - [Building a Datum Hierarchy](#building-a-datum-hierarchy)
    - [Store Provider](#store-provider)
    - [Lookups and overrides in Hierarchy](#lookups-and-overrides-in-hierarchy)
    - [Variable Substitution in Path Prefixes](#variable-substitution-in-path-prefixes)
    - [Enriching the Data lookup](#enriching-the-data-lookup)
 5. [Origins](#5-origins)

-------

## 1. Why Datum?

This PowerShell Module enables you to easily manage a **Policy-Driven Infrastructure** using **Desired State Configuration** (DSC), by letting you organise the **Configuration Data** in a hierarchy adapted to your business context, and injecting it into **Configurations** based on the Nodes and the Roles they implement.

This (opinionated) approach allows to raise **cattle** instead of pets, while facilitating the management of Configuration Data (the **Policy** for your infrastructure) and provide defaults with the flexibility of specific overrides, per layers, based on your environment.

The Configuration Data is composed in a customisable hierarchy, where the storage can be using the file system, and the format Yaml, Json, PSD1 allowing all the use of version control systems such as git.

### Notes

The idea follows the model developed by the Puppet, Chef and Ansible communities (possibly others), in the configuration data management area:

- [Puppet Hiera](https://puppet.com/docs/puppet/5.3/hiera_intro.html) and [Role and Profiles method](https://puppet.com/docs/pe/2017.3/managing_nodes/the_roles_and_profiles_method.html) (very similar in principle, as I used their great documentation for inspiration. Thanks Glenn S. for the pointers, and James McG for helping me understand!)
- [Chef Databags, Roles and attributes](https://docs.chef.io/policy.html) (thanks Steve for taking the time to explain!)
- [Ansible Playbook](http://docs.ansible.com/ansible/latest/playbooks_intro.html) and [Roles](http://docs.ansible.com/ansible/latest/playbooks_reuse_roles.html) (Thanks Trond H. for the introduction!)

Although not in v1 yet, Datum is currently used in Production to manage several hundreds of machines, and is actively maintained.
A stable v1 release is expected for March 2018, while some concepts are thought through, and prototype code refactored.

## 2. Getting Started & Concepts

### Data Layers and Precedence

To simplify the key concept, a Datum hierarchy is some blocks of data (nested hashtables) organised in layers, so that a subset of data can be overridden by another block of data from another layer.

Assuming you have configured two layers of data representing:

- Per Node Overrides
- Generic Role Data

If you Define a data block for the Generic data:

```yaml
# Generic layer
Data1:
  Property11: DefaultValue11
  Property12: DefaultValue12

Data2:
  Property21: DefaultValue21
  Property22: DefaultValue22
```

You can transform the Data by **overriding** what you want in the _per Node override_:

```yaml
Data2:
  Property21: NodeOverrideValue21
  Property22: NodeOverrideValue22
```

The resulting data would now be:

```yaml
# Generic layer
Data1:
  Property11: DefaultValue11
  Property12: DefaultValue12

Data2:
  Property21: NodeOverrideValue21
  Property22: NodeOverrideValue22
```

The order of precedence you define for your layers define the **Most specific** (at the top of your list), to the **Most generic** (at the bottom).

On the file system, this data could be represented in two folders, one per layer, and a Datum configuration file, a Datum.yml

```text
C:\Demo
│   Datum.yml
├───NodeOverride
│       Data.yml
└───RoleData
        Data.yml
```

The Datum.yml would look like this (the order is important):

```yaml
ResolutionPrecedence:
  - NodeOverride\Data
  - RoleData\Data
```

You can now use Datum to lookup the 'Merged Data', per key:

```PowerShell
$Datum = New-DatumStructure -DefinitionFile .\Demo\Datum.yml

Lookup 'Data1' -DatumTree $Datum
# Name                           Value
# ----                           -----
# Property11                     DefaultValue11
# Property12                     DefaultValue12

Lookup 'Data2' -DatumTree $Datum
# Name                           Value
# ----                           -----
# Property21                     NodeOverrideValue21
# Property22                     NodeOverrideValue22
```

This demonstrate the override principle, but it will always return the same thing. How do we make it **relative to a Node's meta data**?

### Path Relative to $Node

The idea is that we want to apply the override only on certain conditions, that could be expressed like:

- A node is given the role _SomeRole_, it's in _London_, and is named _SRV01_
- The Role _SomeRole_ defines default data for Data1 and Data2
- But because _SRV01_ is in _London_, use **Data2** defined _in the **london** location_ instead (leave Data1 untouched).

In this scenario we would create two layers as per the file layout below:

```text
Demo2
│   Datum.yml
├───Locations
│       London.yml
└───Roles
        SomeRole.yml
```

```yaml
# SomeRole.yml
Data1:
  Property11: RoleValue11
  Property12: RoleValue12

Data2:
  Property21: RoleValue21
  Property22: RoleValue22
```

```yaml
# London.yml
Data2:
  Property21: London Override Value21
  Property22: London Override Value22
```

Now let's create a `Node` hashtable that describe our SRV01:

```PowerShell
$SRV01 = @{
    Nodename = 'SRV01'
    Location = 'London'
    Role     = 'SomeRole'
}
```

Let's create **SRV02** for witness, which is in **Paris** (the override won't apply).

```PowerShell
$SRV02 = @{
    Nodename = 'SRV02'
    Location = 'Paris'
    Role     = 'SomeRole'
}
```

And we configure the `Datum.yml`'s Resolution Precedence with relative paths using the Node's properties:

```Yaml
# Datum.yml
ResolutionPrecedence:
  - 'Locations\$($Node.Location)'
  - 'Roles\$($Node.Role)'
```

We can now _mount_ the Datum tree, and do a lookup in the context of a Node:

```PowerShell
Import-Module Datum
$Datum = New-DatumStructure -DefinitionFile .\Datum.yml

lookup 'Data1' -Node $SRV01 -DatumTree $Datum
# Name                           Value
# ----                           -----
# Property11                     RoleValue11
# Property12                     RoleValue12


lookup 'Data2' -Node $SRV01 -DatumTree $Datum

# Name                           Value
# ----                           -----
# Property21                     London Override Value21
# Property22                     London Override Value22
```

And for our witness, not in the London location, Data2 is not overridden:

```PowerShell
lookup 'Data2' -Node $SRV02 -DatumTree $Datum

# Name                           Value
# ----                           -----
# Property21                     RoleValue21
# Property22                     RoleValue22
```

Magic!

## 3. Intended Usage

The overall goal, better covered in the book [Infrastructure As Code](http://infrastructure-as-code.com/book/) by Kief Morris, is to enable a team to "_quickly, easily, and confidently adapt their infrastructure to **meet the changing needs of their organization**_".

To do so, we define our Infrastructure in a set of Policies: human-readable documents describing the intended result (or, Desired State), in structured, declarative aggregation of data, that are also usable by computers: **The Configuration Data**.

We then interpret and transform the data to pass it over to the platform (DSC) and technology components (DSC Resources) grouped in manageable units (Resources, Configurations, and PowerShell Modules).

Finally, the decentralised execution of the platform can let the nodes converge towards their policy.

The policies and their execution are composed in layers of abstraction, so that people with different responsibilities, specialisations and accountabilities have access to the right amount of data in the layer they operate for their task.

As it simplest, a scalable implementation regroups:

- A Role defining the configurations to include, along with the data,
- Nodes implementing that role,
- Configurations (DSC Composite Resources) included in the role,

> The abstraction via roles allows to apply a generic 'template' to all nodes, while enabling Node specific data such as Name, GUID, Encryption Certificate Thumbprint for credentials.

### _Policy for Role 'WindowsServerDefault'_

At a high level, we can compose a Role that will apply to a set of nodes, with what we'd like to see configured.

In this document, we define a generic role we intend to use for Windows Servers, and include the different Configurations we need (Shared1,SoftwareBaseline).

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

The  Software baseline for this role is self documenting. Its specific data apply to that role, and can be different for another role, while the underlying code would not change.
Adding a new package to the list is simple and does not require any DSC or Chocolatey knowledge.

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

Finally, the root configuration is where each node is processed (and the Magic happens).

We import the Module or DSC Resources needed by the Configurations, and for each Node, we `lookup` the Configurations implemented by the policies (`Lookup 'Configurations'`), and for each of those we `lookup` for the parameters that applies and [splat](https://technet.microsoft.com/en-us/library/gg675931.aspx) them to the DSC Resources ([sort of...](https://gaelcolas.com/2017/11/05/pseudo-splatting-dsc-resources/)).

**This file does not need to change, it dynamically uses what's in `$ConfigurationData`!**

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

## 4. Under the hood

Although Datum has been primarily targeted at DSC Configuration Data, it can be used in other contexts where the hierarchical model and lookup makes sense.

### Building a Datum Hierarchy

The Datum hierarchy, similar to [Puppet's Hiera](https://puppet.com/docs/puppet/5.0/hiera_intro.html), is defined typically in a [**Datum.yml**](.\Datum\tests\Integration\assets\DSC_ConfigData\Datum.yml) at the base of the Config Data files.
Although Datum comes only with a built-in _Datum File Provider_ (Not [SHIPS](https://github.com/PowerShell/SHiPS)) supporting the **JSON, Yaml, and PSD1** format, it can call external PowerShell modules implementing the Provider functionalities.

#### Datum Tree's Root Branches

A branch of the Datum Tree would be defined within the DatumStructure of the Datum.yml like so:

```yaml
# Datum.yml
DatumStructure:
  - StoreName: AllNodes
    StoreProvider: Datum::File
    StoreOptions:
      Path: "./AllNodes"
```

Instantiating a variable from that definition would be done with this:
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

So, what should those store providers look like? What do they do?

In short, they abstract the underlying data storage and format, in a way that will allow us to consistently do **key/value lookups**.

The main reason(s) it is not based on [SHIPS](https://github.com/PowerShell/SHiPS) (or Jim Christopher, _aka [@beefarino](https://twitter.com/beefarino)_'s [Simplex module](https://github.com/beefarino/simplex), which I tried and enjoyed!), is that the PowerShell Providers did not seem to provide enough abstraction for **read-only key/value pair access**. These are still very useful (and used) as an intermediary abstraction, such as the FileSystem provider used in the [Datum FileProvider](./Datum/Classes/FileProvider.ps1).

In short, I wanted an uniform key, that could abstract the container, storage, and the structure within the Format.
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

However, while the notation with Path Separator (`\`) is used for **lookups** (more on this later), the provider abstracts the storage+format using the familiar **dot notation**.

From the example above where we loaded our Datum Tree, we'd use the following to return the value:
> `$Datum.AllNodes.SERVER01.MetaData.Subkey`

So we're just accessing variable properties, and our Config Data stored on the FileSystem, is just _mounted_ in a variable (in case of the FileProvider).

With the **dot notation** we have access using absolute keys to all values via the root `$datum`, but this is not much different from having all data in one big hashtable or PSD1 file... This is why we have...

#### Lookups and overrides in Hierarchy

We can mount different _Datum Stores_ (unit of Provider + Parameters) as branches onto our `root` variable.
Typically, I mount the following structure (with many more files not listed here):

```text
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

`Datum.yml` defines another section for **ResolutionPrecedence**: this is an ordered list of _prefix_ to use to search for a relative path, from the most specific to the most generic.

Should you do a `Lookup` for a relative path of `property\subkey`, and the Yaml would contain the following block:

```yaml
ResolutionPrecedence:
  - 'AllNodes'
  - 'Environments'
  - 'Location'
  - 'Roles\All'

```

In this case the lookup function would _try_ the following absolute paths sequentially:

```PowerShell
$Datum.AllNodes.property.Subkey
$Datum.Environments.property.Subkey
$Datum.Location.property.Subkey
$Datum.Roles.All.property.Subkey
```

Although you can configure Datum to behave differently based on your needs, like merging together the data found at each layer, the most common and simple case, is when you only want the **'MostSpecific'** data defined in the hierarchy (and this is the default behaviour).

In that case, even if you usually define the data in the `roles` layer (the most generic layer), if there's an override in a more specific layer, it will be used instead.

But the ordering shown above is not very flexible. How do we apply the relation between the list of roles, the current Node, Environment, location and so on?

### Variable Substitution in Path Prefixes

As we've seen that a Node **implements a role**, is **in a location** and **from a specific Environment**, how do we express these relations (or any relation that would make sense in your context)?

We can define the names and values of those information in the Node meta data (SRV01.yml) like so:

```Yaml
# SRV01.yml
NodeName: 9d8cc603-5c6f-4f6d-a54a-466a6180b589
role: WindowsServerDefault
Location: LON
Environment: DEV
```

And use variable substitution in the `ResolutionPrecedence` block of the `Datum.yml` so that the Search Prefix can be dynamic from one Node to another:

```yaml
# in Datum.yml
ResolutionPrecedence:
  - 'AllNodes\$($Node.Environment)\$($Node.Name)'
  - 'AllNodes\$($Node.Environment)\All'
  - 'Environments\$($Node.Environment)'
  - 'SiteData\$($Node.Location)'
  - 'Roles\$($Node.Role)'
  - 'Roles\All'
```

The `lookup` of the Property Path `'property\Subkey'` would try the following for the above ResolutionPrecedence:

```PowerShell
$Datum.AllNodes.($Node.Environment).($Node.Name).property.Subkey
$Datum.AllNodes.($Node.Environment).All.property.Subkey
$Datum.Environments.($Node.Environment).property.Subkey
$Datum.SiteData.($Node.Location).property.Subkey
$Datum.Roles.($Node.Role).property.Subkey
$Datum.Roles.All.property.Subkey
```

If you remember the part of the Root Configuration:

```PowerShell
 node $ConfigurationData.AllNodes.NodeName {
    # ...
 }
```

It goes through all the Nodes in `$ConfigurationData.AllNodes`, so the absolute path is changing based on the current value of `$Node`.

### Enriching the Data lookup

#### Datum Tree

Regardless of the Datum Store Provider used (there's only the Datum File Provider built-in,
but you can write your own), Datum tries to handle the data similarly to an ordered case-insensitive Dictionary, where possible (i.e. PSD1 don't support Ordering).
All data is referenced under one variable, so it looks like a big tree with many branches and leafs like the one below.

```
$Datum
  +
  |
  +--+AllNodes
  |    +  DEV
  |    |  +SRV01
  |    |   ++ NodeName: SRV01
  |    |      role: Role1
  |    |      Location: Lon
  |    |      ExampleProperty1: 'From Node'
  |    |      Test: '[TEST=Roles\Role1\Shared1\DestinationPath
  |    |
  |    +-+PROD
  |
  +--+Environments
  |    +
  |    +-+DEV
  |    |      Description: 'This is the DEV Environment'
  |    +-+PROD
  |           Description: 'This is the PROD Environment'
  |
  +--+Roles
  |    +-+Role1
  |           Configurations
  |               - Shared1
  |
  +--+SiteData
       +-+Lon
```

If you provide a key, Datum will return All values underneath (to the right):
```PowerShell
$Datum.AllNodes.Environments

# DEV                 PROD
# ---                 ----
# {Description, Test} {Description}
```

#### Lookup Merging Behaviour

In the Tree described above, the Lookup function iterates through the ResolutionPrecedence's key prefix, and append the provided key suffix:

For the following ResolutionPrecedence:
```yaml
ResolutionPrecedence:
  - 'AllNodes\$($Node.Environment)\$($Node.Name)'
  - 'Roles\$($Node.Role)'
  - 'Roles\All
```

Within the `$Node` block, doing `Lookup 'Configurations'` will actually look for:
 - `$Datum.AllNodes.($Node.Environment).($Node.Name).Configurations`
 - `$Datum.Roles.($Node.Role).Configurations`
 - `$Datum.Roles.All.Configurations`

By default the merge behaviour is to **not merge**, which means the first occurence will be returned and the lookup stopped.

The other merge behaviours depends on the (rough) data type of the key to be merged.

Datum identifies 4 [main types](./Datum/Private/Get-DatumType.ps1) in whatever matches first the following:
- **Hashtable**: Hashtables or Ordered Dictionaries
- **Array of Hashtables**: Every `IEnumerable` (except string) that can be casted `-as [Hastable[]]`
- **Array of Base type** objects: Every other `IEnumerable` (except string)
- **Base Types**: Everything else (Int, String, PSCredential, DateTime...)


Their merge behaviour can be defined in the `Datum.yml`, either by using a Short name that reference a preset, or a structure that details the behaviour based on the type.

There is a default Behaviour (`MostSpecific` by default), and you can specify ordered overrides:

```Yaml
default_lookup_options: MostSpecific
```
This is the recommended setting and also the default, so that any sub-key merge has to be explicitly declared like so:
```Yaml
lookup_options:
  <Key Name>: MostSpecific/First|hash/MergeTopKeys|deep/MergeRecursively
  <Other Key>:
    merge_hash: MostSpecific/First|deep|hash/*
    merge_basetype_array: MostSpecific/First|Sum/Add|Unique
    merge_hash_array: MostSpecific/First|Sum|DeepTuple/DeepItemMergeByTuples|UniqueKeyValTuples
    merge_options:
      knockout_prefix: --
      tuple_keys:
        - Name
        - Version
```
The key to be used here is the suffix as used in with the `Lookup` function: e.g. 'Configurations', 'Role1\Data1'.

Each layer will be merged with the result of the previous layer merge:

```
Precedence 0 +
             |
             +---+ Merge 0+-+
             |              |
Precedence 1 +              |
                            +---+Merge 1 +
                            |            |
Precedence 2  +-------------+            |
                                         +----+Merge 2
                                         |
Precedence 4  +--------------------------+

```

The Short name presets represent the following:
```
First, MostSpecific or any un-matched string:
  merge_hash: MostSpecific
  merge_baseType_array: MostSpecific
  merge_hash_array: MostSpecific

hash or MergeTopKeys:
  merge_hash: hash
  merge_baseType_array: MostSpecific
  merge_hash_array: MostSpecific
    merge_options:
      knockout_prefix: '--'

depp or MergeRecursively:
  merge_hash: deep
  merge_baseType_array: Unique
  merge_hash_array: DeepTuple
  merge_options:
    knockout_prefix: --
    tupleKeys:
      - Name
      - Version
```

The Lookup Options can also define keys using a (valid) Regex, for this the key has to start with `^`, for instance:
```Yaml
lookup_options:
  ^LCM_Config\\.*: deep
```

The lookup will **always favor non-regex exact match**, and failing that will then use the **first matching** regex, before falling back on the `default_lookup_option`.

If you've been following that far, you might wonder how it works for subkeys.

Say you want to merge a subkey of a configuration where the role defines the following:

```Yaml
Configurations:
  - SoftwareBaseline

SoftwareBaseline:
  PackageFeed: https://chocolatey.org/api/v2
  Packages:
    - Name: Package1
      Version: v0.0.2
```

And an override file somewhere in the hierarchy:

```Yaml
SoftwareBaseline:
  Packages:
    - Name: Package2
      Version: v4.5.2
```

You want the packages to have a deep tuple merge (that is, merge the hashtables based on matching key/values pairs, where `$ArrayItem.Property1 -eq $otherArrayItem.Property1`, more on this later).

If the default Merge behaviour is MostSpecific, and no override exist for `SoftwareBaseline`, it will never merge Packages, and always return the Most specific.

If you add a Merge behaviour for the key `SoftwareBaseline` of hash, it will merge the keys `PackageFeed` and `Packages` but not below, that means the result for a `Lookup SoftwareBaseline will be (assuming the Role has the lowest ResolutionPrecedence):

```Yaml
SoftwareBaseline:
  PackageFeed: https://chocolatey.org/api/v2
  Packages:
    - Name: Package2
      Version: v4.5.2
```

The `PackageFeed` key is present, but only the most specific `Package` value has been used (there's only 1 package).

To also merge the Packages, you need to also define the Packages Subkey like so:

```Yaml
default_lookup_option: MostSpecific

lookup_options:
  SoftwareBaseline: hash
  SoftwareBaseline\Packages:
    merge_hash_array: DeepTuple
    merge_options:
      TupleKeys:
        - Name
        - Version
```

If you omit the first key (`SoftwareBaseline`), and the Lookup is only doing a lookup of that root key, it will never **'walk down'** the variable to see what needs  merging below the top key. This is the default behaviour in DscInfraSample's `RootConfiguration.ps1`.

However, if you do a lookup directly to the subkey, `Lookup 'SofwareBaseline\Packages'`, it'll now work (as it does not have to **'walk down'** the variable).

#### Lookup Options
 
- Default
- general
- per lookup override

#### Data Handlers - Encrypted Credentials

The data typically stored in Datum is usually defined by the Provider and underlying technology.
For the Datum File Provider, and Yaml format, that would be mostly Text/strings, Integer, and Boolean, composed in dictionary (ordered, hashtable, or PSCustomObject), or collections.

More complex objects, such as credentials can be stored or referenced by use of Data handler.

_(To be Continued)_

------

## 5. Origins

Back in 2014, Steve Murawski then working for Stack Exchange lead the way by implementing some tooling, and open sourced them on the [PowerShell.Org's Github](https://github.com/PowerShellOrg/DSC/tree/development).
This work has been complemented by Dave Wyatt's contribution mainly around the Credential store.
After these two main contributors moved on from DSC and Pull Server mode, the project stalled (in the Dev branch), despite its unique value.

I [refreshed this](https://github.com/gaelcolas/DscConfigurationData) to be more geared for PowerShell 5, and updated the dependencies as some projects had evolved and moved to different maintainers, locations, and name.

As I was re-writing it, I found that the version offered a very good way to manage configuration data, but in a prescriptive way, lacking a bit of flexibility for some much needed customisation (layers and ordering). Steve also pointed me to [Chef's Databag](https://docs.chef.io/data_bags.html), and later I discovered [Puppet's Hiera](https://docs.puppet.com/hiera/3.3/complete_example.html), which is where I get most of my inspiration.