Import-Module ..\..\Datum.psd1 -force

$yml = Get-Content -raw .\datum.yml | ConvertFrom-Yaml

$datum = New-DatumStructure $yml
$Node = @{Name='FileServer01'}
Resolve-Datum -searchPaths $yml.ResolutionPrecedence -Databag $datum -PropertyPath 'ExampleProperty1' -Node $node