ipmo -Force $PSScriptRoot\..\..\..\..\..\Datum
$Node = @{NodeName = 'SRV01'; Name = 'SRV01'; role = 'SomeRole'}
$Node2 = @{NodeName = 'SRV02'; Name = 'SRV02'; role = 'otherRole'}
$datum = New-DatumStructure -DefinitionFile $PSScriptRoot\Datum.yml
$a = Lookup -DatumTree $datum -Node $Node -PropertyPath Disks
$b = Lookup -DatumTree $datum -Node $Node2 -PropertyPath Disks

$a.count
$b.count
