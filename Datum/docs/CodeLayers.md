# Layering the DSC code

While the DSC code can be organised in structure such as Resources, Composite Resources, Configuration and Composite Configurations; those are code constructs providing modularity and re-usability of code, and where the PowerShell module is the natural solution for Packaging them as artifacts.

While those elements are the core components of the interface to the **DSC platform**, it does not prescribe a logical organisation or implementation of DSC as a solution, it only defines the interface with the components of the systems.

In an effort to design an implementation of **a** solution based on DSC, we take an opinionated approach, adding terminology not part of the DSC platform, and recommending practices we believe helps in making a coherent and manageable system at scale.
The approach is heavily inspired from Chef's Roles, Role Attributes, Databags and runlists, or Puppet's Roles and Profiles model backed with Hiera.

## The Problem

To better explain the solution, let's rewind a bit and explain the challenge people usually face with DSC.

The most common scenario for DSC, is to spin up ready-made infrastructure such as Labs, or apply a targeted config in an environment. There's actually relatively few people who have implemented _complete system configurations_, managing a system 'end to end'. Those who do have built their own solution around what Microsoft offers, with different level of success and pain along the way.

The main usage seen in production is to manage a subset of configuration and guard against drift, by using a mix of Named and/or Partial configurations.

Although this is a very good start, and an improvement from the click-next-infrastructure by approaching the infrastructure from code, it is usually difficult to evolve from there.

Named configurations are attractive as they (seem to) offer a greater composability of the DSC policies, and segregation of elements. You can have a generic configuration for a given _role_, and re-use it (that is, the exact same compiled MOF) on many nodes.
The problem here, is because that MOF is used on several nodes, it cannot have ANY identifying information or using different data like: Computer Name, IP address, Machine Specific GUID, Machine Certificate or thumbprint and so on...
Although it's a good aim to have (you should avoid uniqueness, that makes Pets), the reality is that most systems usually need some unique properties, and configuration overrides on specific settings, based on Site, Domain, Platform, Environment and so on...
Usually, in such implementations, all unique parts are managed outside of the Configuration Management software, likely a traditional tool not managed from code (think VM provisioning for instance).

Partials can even decouple the unit of configuration further (at great risks), by allowing those named configuration to be authored, delivered and applied independently from each other, so that one Named config can do something, and the other one undo it, at every DSC Run...

The reason those approaches are popular, is because DSC's composition model seems very limited, and can be without appropriate tooling. 

The first examples and tutorials people see about DSC show how to add Configuration Data to a specific Node under the `AllNodes\SRV01`, and pass it to the configuration. Then the examples shows how to use that data in a configuration, using `$Node.DataKey`, and also introduce the `$ConfigurationData.NonNodeData`. This gets the idea across, but seems to limit that the data can be either Specificly defined to the Node and nowhere else, or in some generic key with no relation to the Node.

The more advanced tutorials show how to leverage those NonNodeData to organise DATA per role, for clarity, but it still misses some capabilities for composing the data, overriding where we need it, when we need it, without changing the code, or the global value.

As an example, imagine you have 3 identical Web servers, all with the exact same configuration. 
You can easily define some basic properties in the configuration data such as:
```PowerShell
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = 'SRV01'
            Name = 'SRV01'
        },
        @{
            NodeName = 'SRV02'
            Name = 'SRV02'
        },
        @{
            NodeName = 'SRV03'
            Name = 'SRV03'
        }
    )
    WebServerRole = @{
        Port = '443'
    }
}
```
In this config data we did a good job at separating the Node Data and the Role data, by creating a _nonNodeData_ for our role called WebServerRole.
Should we want to change that port to all server, a simple change to that configuration data.

The problem is when we want to deploy a new instance, say SRV04, but on a different port, like 8443. If the configuration is using `$ConfigurationData.WebServerRole.Port`, you're out of luck, and you might need to add logic in the configuration, create a new role, or find another way around.

This highlight one common problem, the need for override-only data structures:
1. specify the default value for a Role
2. allow overrides at different logical levels


## The Transform: [DSC Resources + DSC Composite Resources]

The DSC Resource Module should aim to manage one particular technology or stack (think Hyper-V, Jenkins, or Network). The individual Resources within that module should focus on controlling features atomically. It is important to note that this code is running on the **Managed Node** (by the LCM), during the DSC Run, and its parameters are populated by the Configuration Generated during MOF compilation, on the _build_ server.

Sometimes, along with the DSC Resources we bundle those atomic features together in a DSC Composite Resource, to create a slightly higher level of abstraction of that technology: think of bundling a list of Jenkins feature of Jenkins to provide a simple base install as a simpler interface. It is worth bearing in mind that those DSC composite Resources are just interfaces to the bundled DSC Resources, and are _decomposed_ during the MOF compilation process, on the **build server**. On the managed Node side, there is no understanding or execution of DSC Composite Resources, only their inner DSC Resources.
    

## Composite Resources: [profiles]

When assembling different technologies together to solve a specific use case (or story), such as Java + Jenkins for a Build server, we assemble them in a Composite Resource, that wrap the technology into a re-usable unit, creating a simpler, higher level interface to interact with. The composite Resource is executed at Compilation Time when generating the MOF. In DSC, the Composite Resources can be mixed with DSC Resource Module, which is great for flexibility, but confusing for layering our management, so we'll call those one profiles.

- Roles: [roles]
    Definitions of roles wrapping up several profiles (aka. Composite Resources), but where a Node can only have a single Role.

    