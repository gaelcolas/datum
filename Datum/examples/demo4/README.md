# Splatting DSC Resource

A commoon issue when writing DSC Resource, is that the DSL is rigid, so you can't dynamically change the parameters you're setting, like you'd do in a command with Splatting.

To alleviate this, I've created a function that is imported in the User's session (scriptToProcess, because Scope), so that you can splat resources using a function, or it's alias `x` (see example below).

The main reason for this, is also to allow the Roles and Feature model famous with Puppet, where the Resource properties will be stored in Configuration Data files.

```PowerShell
configuration MyConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node localhost
    {
        x File MySplatTest @{
            DestinationPath = 'C:\Configurations\Test.txt'
            Contents = 'this is my content'
        }

        x File MySplatTest2 @{
            DestinationPath = 'C:\Configurations\Test2.txt'
            Contents = 'this is my content'
            DependsOn = '[File]MySplatTest'
        }

        $MyHtParams = @{
            DestinationPath = 'C:\MyTest.txt'
            Contents = 'Splatting is useful when the params come from config data'
        }
        x File $MyHtParams
    }
}
```