if($PSScriptRoot) {
    $here = $PSScriptRoot
} else {
    $here = 'C:\src\Datum\Datum\examples\demo3'
}
pushd $here

. $here\..\..\classes\Node.ps1

$Node1Data = @{
    Name = 'localhost'
    Role = 'FileServer'
    Location = 'Site01'
    NodeName = 'localhost'
    ExampleProperty1 = 'From Node'
}

$Node2Data = @{
    Name = 'Server02'
    Role = 'Server'
    Location = 'Site01'
    NodeName = '9f236666-aac2-43f4-a3e7-bf947ee06a92'
    ExampleProperty1 = 'From second Node'
}

$MyData = @{
    AllNodes = @(
        [Node]::new($Node1Data)
        ,[Node]::new($Node2Data)
    )
}


configuration MyConfiguration
{
    node localhost #$AllNodes.NodeName
    {
        #$Value = $Node.Roles.Test.Data.Path
        File ConfigFile
        {
            DestinationPath = 'C:\Configurations\Test.txt'
            Contents = $($Node.Roles.Test.Data.Path)
        }
    }
}

#MyConfiguration -ConfigurationData $mydata -verbose

#(cat -raw .\MyConfiguration\localhost.mof) -replace '\\n',"`r`n"

#popd