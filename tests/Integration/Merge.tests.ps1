using module datum

$here = $PSScriptRoot

Remove-Module -Name datum

Describe 'Merge ' {
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
                Count        = 2
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

        $testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'Configurations'
                Value        = 'NetworkIpConfiguration', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Configurations'
                Value        = 'NetworkIpConfiguration', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'Configurations'
                Value        = 'NetworkIpConfiguration', 'FilesAndFolder', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'WindowsFeatures\Name'
                Value        = '-Telnet-Client', 'File-Services'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'WindowsFeatures\Name'
                Value        = 'File-Services', 'Web-Server', '-Telnet-Client'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'WindowsFeatures\Name'
                Value        = 'File-Services', 'Web-Server', 'XPS-Viewer', '-Telnet-Client'
            }
        )

        It "The value of Datum <PropertyPath> for node <Node> should be '<Value>'." -TestCases $testCases {
            param ($Node, $PropertyPath, $Value)

            $n = $AllNodes | Where-Object NodeName -EQ $Node
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $n) | Sort-Object | Should -Be ($Value | Sort-Object)
        }
    }

    Context 'Hashtable merge behavior' {

        $testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged'
                Count        = 6
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged'
                Count        = 6
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged'
                Count        = 6
            }

            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationNonMerged'
                Count        = 1
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationNonMerged'
                Count        = 1
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationNonMerged'
                Count        = 1
            }
        )

        It "The hashtable key count of Datum <PropertyPath> for node <Node> should be '<Count>'." -TestCases $testCases {
            param ($Node, $PropertyPath, $Count)

            $n = $AllNodes | Where-Object NodeName -EQ $Node
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $n).Keys | Should -HaveCount $Count
        }
    }

    Context 'Merge Behavior by testing value content' {

        $testCases = @(
            @{
                Node          = 'DSCFile01'
                PropertyPath  = 'NetworkIpConfigurationMerged\Gateway'
                ExpectedValue = '192.168.10.50'
            }
            @{
                Node          = 'DSCWeb01'
                PropertyPath  = 'NetworkIpConfigurationMerged\Gateway'
                ExpectedValue = $null
            }
            @{
                Node          = 'DSCWeb02'
                PropertyPath  = 'NetworkIpConfigurationMerged\Gateway'
                ExpectedValue = '192.168.20.50'
            }
        )

        It "The value of Datum <PropertyPath> for node <Node> should be '<ExpectedValue>'." -TestCases $testCases {
            param ($Node, $PropertyPath, $ExpectedValue)

            if ($Node -eq 'DSCWeb01')
            {
                Set-ItResult -Skipped -Because 'Bug in Datum kockout behaviour'
            }

            $n = $AllNodes | Where-Object NodeName -EQ $Node
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $n) | Should -Be $ExpectedValue
        }
    }
}


