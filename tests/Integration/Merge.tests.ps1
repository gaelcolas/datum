using module datum

Remove-Module -Name datum

Describe 'Merge ' {
    BeforeAll {
        $here = $PSScriptRoot
        Import-Module -Name datum

        $datum = New-DatumStructure -DefinitionFile (Join-Path -Path $here -ChildPath 'assets\MergeTestData\Datum.yml')
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

        $script:testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged\Interfaces\Destination'
                Count        = 9
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged\Interfaces\Destination'
                Count        = 6
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged\Interfaces\Destination'
                Count        = 9
            }

            @{
                Node         = 'DSCFile01'
                PropertyPath = 'WindowsFeatures\Name'
                Count        = 2
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'WindowsFeatures\Name'
                Count        = 3
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'WindowsFeatures\Name'
                Count        = 4
            }

            @{
                Node         = 'DSCFile01'
                PropertyPath = 'Configurations'
                Count        = 3
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Configurations'
                Count        = 2
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'Configurations'
                Count        = 3
            }
        )

        It "The count of Datum <PropertyPath> for node <Node> should be '<Count>'." -TestCases $testCases {
            param ($Node, $PropertyPath, $Count)

            $n = $AllNodes | Where-Object NodeName -EQ $Node
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $n) | Should -HaveCount $Count
        }

        $script:testCases = @(
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
                PropertyPath = 'NetworkIpConfigurationMerged\Interfaces\Destination'
                Value        = '192.168.11.0/24', '192.168.22.0/24', '192.168.33.0/24', '192.168.10.0/24', '192.168.20.0/24', '192.168.30.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged\Interfaces\Destination'
                Value        = '192.168.12.0/24', '192.168.23.0/24', '192.168.34.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged\Interfaces\Destination'
                Value        = '192.168.12.0/24', '192.168.23.0/24', '192.168.34.0/24', '192.168.10.0/24', '192.168.20.0/24', '192.168.30.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }

            @{
                Node         = 'DSCFile01'
                PropertyPath = 'WindowsFeatures\Name'
                Value        = '-Telnet-Client', 'File-Services'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'WindowsFeatures\Name'
                Value        = 'File-Services', '-Telnet-Client', 'Telnet-Server'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'WindowsFeatures\Name'
                Value        = 'File-Services', 'Web-Server', 'XPS-Viewer', '-Telnet-Client'
            }
        )

        It "The value of Datum <PropertyPath> for node <Node> should be '<Value>'." -ForEach $script:testCases {
            param ($Node, $PropertyPath, $Value)

            $n = $AllNodes | Where-Object NodeName -EQ $Node
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $n) | Sort-Object | Should -Be ($Value | Sort-Object)
        }
    }

    Context 'Hashtable merge behavior' {

        $script:testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged'
                Count        = 3
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged'
                Count        = 2
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged'
                Count        = 3
            }

            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationNonMerged'
                Count        = 1
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationNonMerged'
                Count        = 2
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationNonMerged'
                Count        = 1
            }
        )

        It "The hashtable key count of Datum <PropertyPath> for node <Node> should be '<Count>'." -ForEach $script:testCases {
            param ($Node, $PropertyPath, $Count)

            $n = $AllNodes | Where-Object NodeName -EQ $Node
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $n).Keys | Should -HaveCount $Count
        }
    }

    Context 'Merge Behavior by testing value content' {

        $script:testCases = @(
            @{
                Node          = 'DSCFile01'
                PropertyPath  = 'NetworkIpConfigurationMerged'
                Value         = 'ConfigureIPv6'
                ExpectedValue = '-1'
            }
            @{
                Node          = 'DSCWeb01'
                PropertyPath  = 'NetworkIpConfigurationMerged'
                Value         = 'ConfigureIPv6'
                ExpectedValue = 2
            }
            @{
                Node          = 'DSCWeb02'
                PropertyPath  = 'NetworkIpConfigurationMerged'
                Value         = 'ConfigureIPv6'
                ExpectedValue = '0'
            }
            @{
                Node          = 'DSCFile01'
                PropertyPath  = 'NetworkIpConfigurationMerged'
                Value         = 'DisableNetBios'
                ExpectedValue = $true
            }
            @{
                Node          = 'DSCWeb01'
                PropertyPath  = 'NetworkIpConfigurationMerged'
                Value         = 'DisableNetBios'
                ExpectedValue = $null
            }
            @{
                Node          = 'DSCWeb02'
                PropertyPath  = 'NetworkIpConfigurationMerged'
                Value         = 'DisableNetBios'
                ExpectedValue = $false
            }
            @{
                Node          = 'DSCFile01'
                PropertyPath  = 'NetworkIpConfigurationMerged\Interfaces'
                Value         = 'Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                ExpectedValue = '192.168.10.50'
            }
            @{
                Node          = 'DSCWeb01'
                PropertyPath  = 'NetworkIpConfigurationMerged\Interfaces'
                Value         = 'Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                ExpectedValue = $null
            }
            @{
                Node          = 'DSCWeb02'
                PropertyPath  = 'NetworkIpConfigurationMerged\Interfaces'
                Value         = 'Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                ExpectedValue = '192.168.10.50'
            }
        )

        It "The value of Datum <PropertyPath> for node <Node> should be '<ExpectedValue>'." -ForEach $script:testCases {
            param ($Node, $PropertyPath, $Value, $ExpectedValue)

            $n = $AllNodes | Where-Object NodeName -EQ $Node
            $result = Resolve-NodeProperty -PropertyPath $PropertyPath -Node $n

            $cmd = [scriptblock]::Create("`$result.$Value")
            &$cmd | Should -Be $ExpectedValue
        }
    }
}
