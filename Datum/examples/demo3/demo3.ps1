. $PSScriptRoot\..\..\classes\Node.ps1

$Node1Data = @{
    Name = 'FileServer01'
    Role = 'FileServer'
    Location = 'Site01'
    NodeName = '718aec80-e8fe-41b5-ac31-fbcd5d0186b1'
    ExampleProperty1 = 'From Node'
}

$Node2Data = @{
    Name = 'Server02'
    Role = 'Server'
    Location = 'Site01'
    NodeName = '9f236666-aac2-43f4-a3e7-bf947ee06a92'
    ExampleProperty1 = 'From second Node'
}

$Node = [Node]::new($Node1Data)
#$Node.Roles.Test
#$Node.Roles.Test.This.Is.Awesome

$MyData = @{
    AllNodes = @(
        [Node]::new($Node1Data)
        ,[Node]::new($Node2Data)
    )
}

configuration MyConfiguration
{

    node $AllNodes.NodeName
    {
        $Node.PSTypeNames -join '; ' | Write-Host

        $Value = $Node.Roles.Test.Data.Path
        File ConfigFile
        {
            DestinationPath = 'C:\Configurations\Test.txt'
            Contents = ((Get-PSCallStack)[5].Position|FL|out-string)
        }
    }
}

MyConfiguration -ConfigurationData $MyData -verbose