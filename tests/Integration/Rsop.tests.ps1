using module datum

Remove-Module -Name datum

Describe "RSOP tests based on 'MergeTestData' test data" {
    BeforeAll {
        $here = $PSScriptRoot
        Import-Module -Name datum

        # $here is set at file scope and should be available here
        # Path should be: tests\Integration\assets\MergeTestData\Datum.yml
        $datumPath = Join-Path -Path $here -ChildPath 'assets\MergeTestData\Datum.yml'
        if (-not (Test-Path $datumPath)) {
            throw "Cannot find Datum.yml at: $datumPath (here = $here)"
        }

        $datum = New-DatumStructure -DefinitionFile $datumPath
        $allNodes = $datum.AllNodes.psobject.Properties | ForEach-Object {
            $node = $Datum.AllNodes.($_.Name)
            (@{} + $Node)
        }

        $global:configurationData = @{
            AllNodes = $allNodes
            Datum    = $datum
        }

        if (-not $BuildModuleOutput) {
            $BuildModuleOutput = "$here\..\..\output"
        }

        $rsopPath = Join-Path -Path $BuildModuleOutput -ChildPath RSOP
        $rsopWithSourcePath = Join-Path -Path $BuildModuleOutput -ChildPath RsopWithSource
        mkdir -Path $rsopPath, $rsopWithSourcePath -Force | Out-Null
    }

    Context 'Base-Type array merge behavior' {

        $testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'Configurations'
                Value        = 'NetworkIpConfigurationMerged', 'WindowsFeatures', 'FilesAndFolders'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Configurations'
                Value        = 'NetworkIpConfigurationMerged', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'Configurations'
                Value        = 'NetworkIpConfigurationMerged', 'FilesAndFolders', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Destination'
                Value        = '192.168.11.0/24', '192.168.22.0/24', '192.168.33.0/24', '192.168.10.0/24', '192.168.20.0/24', '192.168.30.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Destination'
                Value        = '192.168.12.0/24', '192.168.23.0/24', '192.168.34.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Destination'
                Value        = '192.168.12.0/24', '192.168.23.0/24', '192.168.34.0/24', '192.168.10.0/24', '192.168.20.0/24', '192.168.30.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'WindowsFeatures.Name'
                Value        = '-Telnet-Client', 'File-Services'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'WindowsFeatures.Name'
                Value        = 'File-Services', '-Telnet-Client', 'Telnet-Server'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'WindowsFeatures.Name'
                Value        = 'File-Services', 'Web-Server', 'XPS-Viewer', '-Telnet-Client'
            }
        )

        It "The value of Datum RSOP property '<PropertyPath>' for node '<Node>' should be '<Value>'." -ForEach $testCases {
            param ($Node, $PropertyPath, $Value)

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

    Context 'Hashtable array merge behavior' {

        $testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.IpAddress'
                Value        = '192.168.10.100'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                Value        = '192.168.10.50'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.IpAddress'
                Value        = '192.168.10.101'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                Value        = $null
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.IpAddress'
                Value        = '192.168.10.102'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                Value        = '192.168.20.50'
            }
        )

        It "The value of Datum RSOP property '<PropertyPath>' for node '<Node>' should be '<Value>'." -ForEach $testCases {
            param ($Node, $PropertyPath, $Value)

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

    Context 'Cache cmdlets' {

        BeforeAll {
            Clear-DatumRsopCache
        }

        It "'Clear-DatumRsopCache' returns `$null" {
            Get-DatumRsopCache | Should -Be $null
        }

        It "'Get-DatumRsopCache' returns the RSOP Cache" {
            $rsop = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes
            $rsopCache = Get-DatumRsopCache

            $rsop.Count | Should -Be $rsopCache.Count
        }

    }
}
