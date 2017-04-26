Import-Module $PSScriptRoot\..\..\Datum.psd1 -force

pushd $PSScriptRoot

$yml = Get-Content -raw $PSScriptRoot\datum.yml | ConvertFrom-Yaml

$datum = New-DatumStructure $yml
$ConfigurationData = @{
    AllNodes = $Datum.AllNodes.psobject.Properties | % { $Datum.AllNodes.($_.Name) }
    Datum = $Datum
}

$Node = $Configurationdata.Allnodes[1]
"`r`nSearching most specific Property 'ExampleProperty1' for $($Node.Name):"
Resolve-Datum -searchPaths $yml.ResolutionPrecedence -DatumStructure $datum -PropertyPath 'ExampleProperty1'

#Searching most specific Property 'ExampleProperty1' for FileServer01:
#From Node


"`r`nSearching all Properties 'ExampleProperty1' for $($Node.Name):"
Resolve-Datum -searchPaths $yml.ResolutionPrecedence -DatumStructure $datum -PropertyPath 'ExampleProperty1' -SearchBehavior 'AllValues'

#Searching all Properties 'ExampleProperty1' for FileServer01:
#From Node
#From Site
#From All SiteData
#From Role
#From All Roles

"`r`nAll Property 'FileServer\datum\mergeMe' for $($Node.Name):"
Resolve-Datum -searchPaths $yml.ResolutionPrecedence -DatumStructure $datum -PropertyPath 'FileServer\datum\mergeMe' -SearchBehavior 'AllValues'

popd