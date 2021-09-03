using module datum

$here = $PSScriptRoot

Remove-Module -Name datum

Describe "RSOP tests based on 'DscWorkshopConfigData' test data" {
    BeforeAll {
        Import-Module -Name datum

        $datum = New-DatumStructure -DefinitionFile (Join-Path -Path $here -ChildPath '.\assets\MergeTestData\Datum.yml' -Resolve)
        $allNodes = $datum.AllNodes.psobject.Properties | ForEach-Object {
            $node = $Datum.AllNodes.($_.Name)
            (@{} + $Node)
        }

        $global:configurationData = @{
            AllNodes = $allNodes
            Datum    = $datum
        }
    }

    Context 'Base-Type array merge behavior' {

        $testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.IpAddress'
                Value        = '192.168.10.100'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Gateway'
                Value        = '192.168.10.50'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.IpAddress'
                Value        = '192.168.10.102'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Gateway'
                Value        = '192.168.20.50'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'Configurations'
                Value        = 'WindowsFeatures', 'FilesAndFolders', 'NetworkIpConfigurationMerged'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Configurations'
                Value        = 'WindowsFeatures', 'NetworkIpConfigurationMerged'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'Configurations'
                Value        = 'WindowsFeatures', 'NetworkIpConfigurationMerged', 'FilesAndFolders'
            }
        )

        It "The value of Datum RSOP property '<PropertyPath>' for node '<Node>' should be '<Value>'." -TestCases $testCases {
            param ($Node, $PropertyPath, $Value)

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes -Filter { $_.NodeName -eq $Node }
            $cmd = [scriptblock]::Create("`$rsop.$PropertyPath")
            & $cmd | Sort-Object | Should -Be ($Value | Sort-Object)
        }

    }
}
