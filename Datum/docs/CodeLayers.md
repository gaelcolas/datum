# Layering the DSC code

While the DSC code can be organised with constructs such as Resources, Composite Resources, Configuration and Composite Configurations; those are providing modularity and re-usability of code, and where the PowerShell module is the natural solution for Packaging them as artifacts.

While those elements are the core components of the interface to the **DSC platform**, it does not prescribe a logical organisation or implementation of DSC as a solution, it only defines the interface with the components of the systems.

In an effort to design an implementation of **a** solution based on DSC, we take an opinionated approach, adding terminology not part of the DSC platform, and recommending practices we believe helps in making a coherent and manageable system at scale.
The approach is heavily inspired from Chef's Roles, Role Attributes, Databags and runlists, or Puppet's Roles and Profiles model backed with Hiera.

## The Problem(s)

To better explain the solution, let's rewind a bit and explain some of the challenges people usually face with DSC.

The most common usage for DSC, is to spin up ready-made infrastructure such as Labs, or apply a targeted config in an environment. There's actually relatively few people who have implemented _complete system configurations_, managing a complex system 'end to end'. Those who do have built their own solution around what Microsoft offers, with different level of success and pain along the way.

The main usage seen in production is to manage a subset of configuration and guard against drift, by using a mix of Named and/or Partial configurations.

Although this is a very good start, and an improvement from the click-next-infrastructure by approaching the infrastructure from code, it is usually difficult to evolve from there.

Named configurations are attractive as they (seem to) offer a greater composability of the DSC policies, and segregation of elements. You can have a generic configuration for a given _role_, and re-use it (that is, the exact same compiled MOF) on many nodes.
The problem here, is because that MOF is used on several nodes, it cannot have ANY identifying information or use specific data like: Computer Name, IP address, Machine Specific GUID, Machine Certificate or thumbprint and so on...
Although it's a goal to have (you should avoid uniqueness, that makes Pets and snowflakes), the reality is that most systems usually need some unique properties, and configuration overrides on specific settings, based on Site, Domain, Platform, Environment and so on...
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

The problem is when we want to deploy a new instance, say SRV04, but on a different port, like 8443. If the configuration is using `$ConfigurationData.WebServerRole.Port`, you're out of luck, and you might need to add conditional logic in the configuration, create a new role, or find another way around.

This highlight one common problem, the need for override-only data structures:
1. specify the default value for a Role
2. allow overrides at different logical levels

Overrides usually follow a logical hierarchy in the user's context, from the most Generic to the most specific. To avoid pets and raise cattles, you aim to only specify settings in the most generic layer. But real life will throw cases where you have to have some deviation from it:
- Environment Specific: In my environment _`x`_, I want to override the backup retention period.
- Site specific: In my site _`y`_ the encryption algorithm must be different.
- Node Specific: That Node _`z`_ should listen on port 80, during some troubleshooting.

With a hierarchical, override-only data structure you can also override the same setting at different layers of the hierarchy.

For example, you have a default value for the port to use for a web service, overidden for your test environment, but overriden again for a specific Node of that environment during some testing.

Another common case, is where you want those 'layers' to not completely replace the value, but do something more clever: merging the data.

An example could be to have a baseline of software to be present for a role, but a specific site may require extra packages, and hence will define those extra as a Site Override. Then again, during testing we may want to add an extra package to a specific node.

The configuration will have to merge the package list from all layers, and return only unique values to generate the MOF.

## The Resources: [DSC Resources + DSC Composite Resources]

Although the **DSC Resources** and **DSC Composite Resources** can be used in different ways, we're defining the following as our best practice: We make a slight difference between what we call `Resources` from the `DSC Resources` or `DSC Composite Resources`. The former defines usage of the code constructs in our solution, while the latter are the code construct types of the DSC Framework.

A **DSC Resource Module** (That is a PowerShell module with DSC Resources and Composites) should aim to manage one particular technology or stack (think Hyper-V, Jenkins, or Firewall). The individual **DSC Resources** within that module should focus on controlling features _atomically_. It is important to note that this code is running on the **Managed Node** (by the LCM), during the DSC Run, and its parameters are populated by the DSC Configuration during MOF compilation, on the _build_ server (the node that ran the DSC configuration to generate the MOF).

Sometimes, along with the **DSC Resources** we bundle those atomic features together in a **DSC Composite Resource**, to create a slightly higher level of abstraction of that technology: think of bundling a list of Jenkins features together to provide a simple base install as a simpler interface. It is worth bearing in mind that those DSC composite Resources are just interfaces to the bundled DSC Resources, and are _decomposed_ during the MOF compilation process, on the **build server**. On the managed Node side, there is no understanding or execution of **DSC Composite Resources**, only their inner DSC Resources.

Those **DSC Resources** and **DSC Composite Resources** should be packaged in functionally coherent **modules** (the PowerShell Module kind) managing a single stack or technology. The goal of those constructs is to abstract the code and provide an Interface by exposing parameters.


## The Configurations: [Configuration + Composite Resources]

When assembling different technologies together to solve a specific use case (or story --> hint to the method to use), such as Java + Jenkins for a Build server, we assemble them in a **DSC Composite Resource**, that wrap the technologies into a re-usable unit, creating a simpler & cohesive interface, with a higher level of abstraction to interact with. The **DSC composite Resource** is executed at MOF Compilation Time when generating the MOF.

In our logical segmentation, those **DSC composite Resources** serve as _Configuration blocks_, because there can be only one **DSC Configuration** construct instance, that is if we want to keep the code manageable (managing the configuration's Config Data, keeping Configuration blocks in separate file, and benefiting from the DSL syntax for readability).

As the `DSC Configuration` block can only be unique for the reasons above, we sometime call it `root configuration` to differentiate it from the other code construct, the **DSC Composite Resources**. The reason for that naming is (to try) to disambiguate the confusion induced by the names of the Code Constructs. Ideally, you'd have little direct interaction with the root configuration.

One of the great advantage of **DSC Composite Resource** as a configuration block, is that they can be shared in a familiar versioned artifact, the **PowerShell module**, while specifying dependencies and so on.


## The Roles: [Data]

Finally in our implementation of a solution based on the DSC platform, we define the Role as the wrapper of multiple configuration components (imagine a role composed of the Configuration blocks WindowsBase, SecurityBase, WebServer, MySite1).

The role is not a code construct, but metadata to define:
- A single role per Node
- Multiple Configurations in a Role

This could be defined in a YAML document such as:
```yaml
Role::Jenkins:
  - MyCompanyConfigs::WindowsServerBase
  - MyCompanyConfigs::WebSecurityHardening
  - Jenkins::JenkinsConfig
```

Given the class assigned to a Node, this could result in integrating the Composite Resources for that node such as:
```PowerShell
WindowsServerBase ComputerGeneratedName1 {
    <# ... #>
}

WebSecurityHardening ComputerGeneratedName2 {
    <# ... #>
}

JenkinsConfig ComputerGeneratedName2 {
    <# ... #>
}

```
Those DSC Composite Resources would in turn define DSC Resources, the next level of abstraction.

As you can see, we're now missing a few links:
 - How the Parameters to the configuration and resources works
 - How the Configuration look like