if($PSScriptRoot) {
    $here = $PSScriptRoot
} else {
    $here = 'C:\src\Datum\Datum\examples\demo6'
}
pushd $here

ipmo $here\..\..\Datum.psd1 -force

$yml = Get-Content -raw $PSScriptRoot\datum.yml | ConvertFrom-Yaml

$datum = New-DatumStructure $yml


$ConfigurationData = @{
    AllNodes = @($Datum.AllNodes.psobject.Properties | % { $Datum.AllNodes.($_.Name) })
    Datum = $Datum
}

$Node = $Configurationdata.Allnodes[0]

"Node is $($Node|FL *|Out-String)" | Write-Warning

Lookup -Node $Node -PropertyPath 'Profiles' <#'AllValues'#> -Verbose -Debug | Write-Warning



break
<#
configuration RootConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName PLATFORM
    node $AllNodes.NodeName {
        (Lookup $Node 'Profiles' 'AllValues') | % {
            #Include $_
            lookup $Node $_ | % { x ($_.keys[0]) }
        }
    }
}

MyConfiguration -ConfigurationData $ConfigurationData

(cat -raw .\MyConfiguration\blah.mof) -replace '\\n',"`r`n"

#popd

#>