Import-Module $PSScriptRoot\..\..\Datum.psd1 -force

pushd $PSScriptRoot

$yml = Get-Content -raw $PSScriptRoot\datum.yml | ConvertFrom-Yaml

$datum = New-DatumStructure $yml
$ConfigurationData = @{
    AllNodes = $Datum.AllNodes.psobject.Properties | % { $Datum.AllNodes.($_.Name) }
    Datum = $Datum
}
$Node = $Configurationdata.Allnodes[1]
Resolve-Datum -searchPaths $yml.ResolutionPrecedence -Databag $datum -PropertyPath 'ExampleProperty1' -Node $node
#Resolve-Datum -searchPaths $yml.ResolutionPrecedence -Databag $datum -PropertyPath 'ExampleProperty1' -Node $node

popd