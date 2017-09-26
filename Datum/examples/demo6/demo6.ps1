if($PSScriptRoot) {
    $here = $PSScriptRoot
} else {
    $here = 'C:\src\Datum\Datum\examples\demo6'
}
$Env:PSModulePath += ';'+"$here\Configurations\"

pushd $here
remove-item function:\Resolve-NodeProperty
remove-item Alias:\Lookup

ipmo $here\..\..\Datum.psd1 -force

$yml = Get-Content -raw $here\datum.yml | ConvertFrom-Yaml

$datum = New-DatumStructure $yml

$Environment = 'DEV'

$ConfigurationData = @{
    AllNodes = @($Datum.AllNodes.($Environment).psobject.Properties | % { $Datum.AllNodes.($_.Name) })
    Datum = $Datum
}

$Node = $Configurationdata.Allnodes[0]

#"Node is $($Node|FL *|Out-String)" | Write-Warning

Lookup -Node $Node -PropertyPath 'Configurations' <#'AllValues'#> -Verbose -Debug | Write-Warning

Write-Warning "---------->> Starting Configuration"
configuration RootConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName PLATFORM -ModuleVersion 0.0.1

    node $ConfigurationData.AllNodes.NodeName {
        #File MyFile1 {
        #    Ensure          = 'Present'
        #    DestinationPath = 'C:\test2.txt'
        #    Contents        = 'blahblahblah'
        #}
        #
        #Base1 MyBase {
        #    BaseParam1 = 'this is a test from the root config'
        #}
        #Config1 MyConfig1 {
        #    Config1Param1 = 'this is another test'
        #}
        
        (Lookup $Node 'Configurations') | % {
            $ConfigurationName = $_
            $(Write-Warning "Looking up $ConfigurationName")
            $Properties = $(lookup $Node $ConfigurationName -Verbose -DefaultValue @{})
            $(Write-Warning "Including $($Properties | Convertto-json)")
            #x $ConfigurationName $ConfigurationName $Properties
            Get-DscSplattedResource -ResourceName $ConfigurationName -ExecutionName $ConfigurationName -Properties $Properties
        }
        #>
    }
}

RootConfiguration -ConfigurationData $ConfigurationData

(cat -raw .\RootConfiguration\SRV01.mof) -replace '\\n',"`r`n"

#popd

#>