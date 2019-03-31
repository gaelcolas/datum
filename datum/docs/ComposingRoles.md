# Composing DSC Roles

Another common challenge with DSC, is how to compose DSC configurations.

People have seen the trick of having a Configuration, and the following code within:

```PowerShell
Configuration MyDSCConfig {
    Node $ConfigurationData.AllNodes.nodename {

        if($Node.roles -contains 'MyRole') {
            # do stuff here, like calling DSC Resources
            MyCompositeResource StuffForMyRole {
                # ...
            }
        }

        if($Node.roles -contains 'MyOtherRole') {
            MyOtherResource OtherStuff {
                # ...
            }
        }
    }
}
```

This is a good way to get started and works well for small-ish configurations, but it gets out of hand pretty quickly, as it's hard to read all the `if` statements and their content. Some variant of this are using `Where` clauses around the Node expression.


## Puppet and the [_Role and Profiles_ model](https://puppet.com/docs/pe/2017.2/r_n_p_intro.html)

The puppet community uses and recommend a very neat model for composing _complete system configurations_, while managing the complexity by modularising parts of the code into re-usable and cohesive components, while loosely coupling them.

They also have comprehensive and well-written documentation with real-life  examples available on their website, making it easy to learn.

This article is a quick explanation of the principle and how to do something very similar with DSC.

## The DSC Composition Model

I find the names of the **DSC code constructs** potentially confusing for people not already familiar with their specificities and how to compose them into system configurations.

The DSC code constructs are:
- [DSC Resource](https://msdn.microsoft.com/en-us/powershell/dsc/authoringresourcemof) (or [class based](https://msdn.microsoft.com/en-us/powershell/dsc/authoringresourceclass))
- [DSC Configuration](https://msdn.microsoft.com/en-us/powershell/dsc/configurations)
- [DSC Composite Configuration](https://msdn.microsoft.com/en-us/powershell/dsc/compositeconfigs)
- [DSC Composite Resource](https://msdn.microsoft.com/en-us/powershell/dsc/authoringresourcecomposite)

As you see, to avoid confusion, I like to prefix their name with 'DSC' when talking about the code constructs, in order to separate them clearly from my attempt of vulgarising the composition model for DSC:

- **Configuration Data** [data]
- **Configurations** [DSC Configuration + DSC Composite Resources]
- **Resources** [DSC Resources + DSC Composite Resources]

Yep, until proven otherwise, **I don't find DSC Composite Configurations useful**.

I've already discussed **[the DSC Configuration Data Problem](https://gaelcolas.com/2018/01/29/the-dsc-configuration-data-problem/)** and how it should be structured at a high level, so I'll completely ignore my advice, and _Keep It Super Simple_ to focus on the **Composition Model**.

I see the composition model as a succession of abstraction layers:
- the top layer, the **Configuration Data Layer** is 'tool agnostic' (it's just structured data), and the most high-level. This is where changes happen more often, and should be very declarative and self documenting, representing the business context for the entities it describes (i.e. `Nodes`, but not exclusively). You can call it the **Policies**, because the Data is structured into documents that describe what the entity/object it represents should look like. 
_DSC is the platform to converge the entities into compliance_.

- the middle layer is the **Configuration layer**, where the data is adapted, transformed and massaged slighlty from business-specific structure into something that makes sense for the Resources, with just a **touch** of orchestration (think [dependsOn](https://docs.microsoft.com/en-us/powershell/dsc/configurations#using-dependson) and [waitfor*](https://docs.microsoft.com/en-us/powershell/dsc/crossnodedependencies)...). The configuration usually build a 'layered technology stack', in a cohesive unit that represents an entity. For instance you could compose NIC, System Disk, OS, Domain, Accounts to represent a basic system.

- At the bottom, the **Resource layer** is the interface with a specific technology, where atomic changes are made. It should have very little logic handling the overall goal, but transpose the DSL into actionable and idempotent actions. It usually is the DSC interface to imperative modules, whether they're PowerShell modules, or other such as [Python or C DSC resources for Linux](https://docs.microsoft.com/en-us/powershell/dsc/lnxgroupresource).


The common mistakes I've seen, is **over-specializing** the middle or lower layer, usually **in response to the challenge** posed with managing **Configuration Data**.

This surfaces when using too many [ DSC Script Resources](https://docs.microsoft.com/en-us/powershell/dsc/scriptresource) (instead of custom [DSC Resources](https://docs.microsoft.com/en-us/powershell/dsc/authoringresourcemof)), or having big monolithic configurations with lots of logic, and unhelpful parameters (i.e. passing the whole `$ConfigurationData`).

From these layers, how can we compose Configurations in a flexible way, that can be self-documenting, flexible, with a reduced _change domain_ (aka change scope)?


## One Role, multiple Configurations

If we think about some kind of **application running on a server**, you can easily spot a **layered stack**. Well, I just described it, you have the **'Server'** and the **'Application'**.

Now, we may want to run that application on two different types of server, so we'd have **ServerType1** and **ServerType2** both running an instance of **Application**.

That gives us 2 unique compositions:
- ServerType1_Application
- ServerType2_Application

Creating a unique DSC Composite Resource full of if statement to manage this could work, but it would be painful to use when you only want to change `ServerType1_Application`.

Also, if `ServerType1` and `ServerType2` are relatively similar, maybe only the **configuration data changes** (such as Disk Size, OS Version, NIC Configuration), and only one DSC Composite Resource is required for `ServerType`, on top of the `Application` DSC Composite Resource.

One way we could interpret the `ServerType1_application` composition could be:

> **ServerType1_Application:**
>
> Apply the `ServerType` Configuration,
>
> with \<ServerType1 Data\>,
> 
> and the `Application` Configuration,
>
>  with the \<Application Data\>

In Puppet's _Role and Profiles_ model, that's a Role definition, including two profiles. For DSC I'd call it the **Roles and Configurations model**.

We can now imagine that we associate several `Nodes` with this role, and we can start raising cattles! The nodes kinda 'instantiate' the Roles.

Assuming a Configuration Data structure like the one below, we have simple Nodes implementing Unique roles, composed of re-usable Configurations but with Data specific to the role.

```PowerShell
$ConfigurationData = @{
    AllNodes = @(
        @{
            Nodename = 'SRV01'
            Role = 'ServerType1_Application'
        },
        @{
            Nodename = 'SRV02'
            Role = 'ServerType2_Application'
        }
    )

    Roles = @{
        ServerType1_Application = @{
            Configurations = @('ServerType','Application')
            ServerType = @{
                # ServerType1 Data
            }
            Application = @{
                #Application Data
            }
        }

        ServerType2_Application = @{
            Configurations = @('ServerType','Application')
            ServerType = @{
                # ServerType1 Data
            }
            Application = @{
                #Application Data
            }
        }
    }
}

```

The Configurations (DSC Composite Resources) would be re-usable, and probably live in different PowerShell modules (maybe one for the Platform and one for the Application or Product).

Some Data would be duplicated here (i.e. the Application Data for each Role), but that's a subject for another time (Datum).

Now the question is how do we make the link between this Configuration Data, and the Configurations?

Easy!

## Splatting things together

I've blogged about [Pseudo-Splatting DSC resources](https://gaelcolas.com/2017/11/05/pseudo-splatting-dsc-resources/), and this is the same principle. DSC Composite Resources behave in a similar way as DSC Resources when compiling MOFs, so we can splat the Parameters defined in our Roles to the respective Resource:

The **powershell pseudo code equivalent** would be:

```PowerShell
foreach($Node in $ConfigurationData.AllNodes) {
    # Retrieving the DSC Composite Resource name to include
    $configurations = $ConfigurationData.Roles.($Node.Role).configurations
    foreach($ConfigurationName in $configurations) {
        $ConfigurationParameters = $ConfigurationData.Roles.($Node.Role).($ConfigurationName)
        # Splat the Configuration Parameters defined in the Role to the Composite resource
        &$ConfigurationName @ConfigurationParameters
    }
}

```

Should we define the function to **'splat' the DSC Composite Resouce** like so (available in Datum):

```PowerShell
function Global:Get-DscSplattedResource {
    [CmdletBinding()]
    Param(
        [String]
        $ResourceName,

        [String]
        $ExecutionName,

        [hashtable]
        $Properties,

        [switch]
        $NoInvoke
    )
    # Remove Case Sensitivity of ordered Dictionary or Hashtables
    $Properties = @{}+$Properties

    $stringBuilder = [System.Text.StringBuilder]::new()
    $null = $stringBuilder.AppendLine("Param([hashtable]`$Parameters)")
    $null = $stringBuilder.AppendLine()
    $null = $stringBuilder.AppendLine(" $ResourceName '$ExecutionName' { ")
    foreach($PropertyName in $Properties.keys) {
        $null = $stringBuilder.AppendLine("$PropertyName = `$(`$Parameters['$PropertyName'])")
    }
    $null = $stringBuilder.AppendLine("}")
    Write-Debug ("Generated Resource Block = {0}" -f $stringBuilder.ToString())
    
    if($NoInvoke.IsPresent) {
        [scriptblock]::Create($stringBuilder.ToString())
    }
    else {
        [scriptblock]::Create($stringBuilder.ToString()).Invoke($Properties)
    }
}
Set-Alias -Name x -Value Get-DscSplattedResource -scope Global
```


The actual DSC would look like this:

```PowerShell
Configuration MyDscConfig {
    # Import the module that has the 'ServerType' configuration
    Import-DscResource -ModuleName Platform
    # Import the module that has the 'Application' Configuration
    Import-DscResource -ModuleName Product

    $ConfigurationData.AllNodes.Nodename {
        $ConfigurationData.Roles.($Node.Role).configurations.Foreach{
            $ConfigurationName = $_
            $ConfigurationParameters = $ConfigurationData.Roles.($Node.Role).($ConfigurationName)

            # This weird notation is to avoid scoping issues when invoking the DSC Composite Resource
            (Get-DscSplattedResource -ResourceName $ConfigurationName -ExecutionName "$($ConfigurationName)_inc" -Properties $ConfigurationParameters -NoInvoke).Invoke($ConfigurationParameters)
        }
    }
}
```
