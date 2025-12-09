using module datum

$here = $PSScriptRoot

BeforeDiscovery {
    # Standard module setup
    if (Get-Module -Name datum -ErrorAction SilentlyContinue) {
        Remove-Module -Name datum -Force
    }
    Import-Module -Name datum -Force

    $script:Datum = New-Datumstructure -DefinitionFile (Join-Path $here '.\assets\DSC_ConfigData\Datum.yml' -Resolve)
    $Environment = 'DEV'
    $AllNodes = @($Datum.AllNodes.($Environment).psobject.Properties | ForEach-Object {
            $Node = $Datum.AllNodes.($Environment).($_.Name)
            $null = $Node.Add('Environment', $Environment)
            if (!$Node.contains('Name') )
            {
                $null = $Node.Add('Name', $_.Name)
            }
            (@{} + $Node)
        })

    $global:configurationData = @{
        AllNodes = $AllNodes
        Datum    = $Datum
    }
    $script:Node = $ConfigurationData.AllNodes[0]

    $script:TestCases = @(
        @{PropertyPath = 'ExampleProperty1'; ExpectedResult = 'From Node' }
        @{PropertyPath = 'Description'; ExpectedResult = 'This is the DEV environment' }
        @{PropertyPath = 'Shared1\Param1'; ExpectedResult = 'This is the Role override!' }
        @{PropertyPath = 'locationName'; ExpectedResult = 'London' }
    )
}

Describe 'Test Datum overrides' {
    BeforeAll {
        # Reload module for test execution
        if (Get-Module -Name datum -ErrorAction SilentlyContinue) {
            Remove-Module -Name datum -Force
        }
        Import-Module -Name datum -Force

        $script:Datum = New-Datumstructure -DefinitionFile (Join-Path $PSScriptRoot '.\assets\DSC_ConfigData\Datum.yml' -Resolve)
        $Environment = 'DEV'
        $AllNodes = @($Datum.AllNodes.($Environment).psobject.Properties | ForEach-Object {
            $Node = $Datum.AllNodes.($Environment).($_.Name)
            $null = $Node.Add('Environment', $Environment)
            if (!$Node.contains('Name')) {
                $null = $Node.Add('Name', $_.Name)
            }
            (@{} + $Node)
        })

        $global:configurationData = @{
            AllNodes = $AllNodes
            Datum    = $Datum
        }
        $script:node = $ConfigurationData.AllNodes[0]
    }

    Context 'Most specific Merge behavior' {


        It "Datum '<PropertyPath>' for Node $($script:node.Name) should be '<ExpectedResult>'." -ForEach $script:TestCases {
            Param($propertyPath, $ExpectedResult)
            Resolve-Datum -searchPaths $script:Datum.__Definition.ResolutionPrecedence -DatumStructure $script:datum -PropertyPath $propertyPath -Node $script:node | Should -Be $ExpectedResult
        }

    }
}
