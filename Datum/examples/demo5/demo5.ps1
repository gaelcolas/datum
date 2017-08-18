if($PSScriptRoot) {
    $here = $PSScriptRoot
} else {
    $here = 'C:\src\Datum\Datum\examples\demo5'
}
pushd $here

ipmo $here\..\..\Datum.psd1 -force


$yml = Get-Content -raw $PSScriptRoot\datum.yml | ConvertFrom-Yaml

$datum = New-DatumStructure $yml

$ConfigurationData = @{
    AllNodes = $Datum.AllNodes.psobject.Properties | % { $Datum.AllNodes.($_.Name) }
    Datum = $Datum
}

$Node = $Configurationdata.Allnodes[1]

"`r`nSearching all Properties 'ExampleProperty1' for $($Node.Name):"
Resolve-Datum -searchPaths $yml.ResolutionPrecedence -DatumStructure $datum -PropertyPath 'ExampleProperty1' -SearchBehavior 'AllValues'


configuration MyConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node $AllNodes.NodeName {
        File myFileRsrc {
            DestinationPath = 'C:\test.txt'
            Contents = $((Lookup $Node 'ExampleProperty1') -join '|')
        }
    }
}

MyConfiguration -ConfigurationData $ConfigurationData

(cat -raw .\MyConfiguration\blah.mof) -replace '\\n',"`r`n"

#popd