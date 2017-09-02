$yml = Get-Content -raw $PSScriptRoot\datum.yml | ConvertFrom-Yaml

$datum = New-DatumStructure $yml

$ConfigurationData = @{
    AllNodes = $Datum.AllNodes.psobject.Properties | % { $Datum.AllNodes.($_.Name) }
    Datum = $Datum
}
