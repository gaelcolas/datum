using module datum

$here = $PSScriptRoot

Remove-Module -Name datum

Describe "Datum Handler tests based on 'DscWorkshopConfigData' test data" {
    BeforeAll {
        Import-Module -Name datum

        $datum = New-DatumStructure -DefinitionFile (Join-Path -Path $here -ChildPath '.\assets\DscWorkshopConfigData\Datum.yml' -Resolve)
        $allNodes = $datum.AllNodes.Dev.psobject.Properties | ForEach-Object {
            $node = $Datum.AllNodes.Dev.($_.Name)
            (@{} + $Node)
        }

        $global:configurationData = @{
            AllNodes = $allNodes
            Datum    = $datum
        }

        $rsopPath = Join-Path -Path $BuildModuleOutput -ChildPath RSOP
        $rsopWithSourcePath = Join-Path -Path $BuildModuleOutput -ChildPath RsopWithSource
        mkdir -Path $rsopPath, $rsopWithSourcePath -Force | Out-Null
    }

    Context 'Base-Type array merge behavior' {

        $testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.IpAddress'
                Value        = '192.168.10.100'
            }
        )

        It "The value of Datum RSOP property '<PropertyPath>' for node '<Node>' should be '<Value>'." -TestCases $testCases {

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes -Filter { $_.NodeName -eq $Node }
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsopWithSource = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes -Filter { $_.NodeName -eq $Node } -IncludeSource
            $nodeRsopWithSourcePath = Join-Path -Path $rsopWithSourcePath -ChildPath "$node.yml"
            $rsopWithSource | ConvertTo-Yaml | Out-File -FilePath $nodeRsopWithSourcePath

            $cmd = [scriptblock]::Create("`$rsop.$PropertyPath")
            & $cmd | Sort-Object | Should -Be ($Value | Sort-Object)
        }
    }
}
