if($PSScriptRoot) {
    $here = $PSScriptRoot
} else {
    $here = 'C:\src\Datum\Datum\examples\demo5'
}
pushd $here

ipmo $here\..\..\Datum.psd1 -force

. $here\LoadConfigData.ps1

configuration RootConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName Common
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