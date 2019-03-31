if ($PSScriptRoot) {
    $here = $PSScriptRoot
}
else {
    $here = Join-Path $pwd.Path '*\tests\Integration\' -Resolve
}

Write-verbose "Here: $here"

Describe 'Test Datum overrides' {
    Context 'Most specific Merge behavior' {
        BeforeAll {

            $Datum = New-Datumstructure -DefinitionFile  (Join-path $here '.\assets\DSC_ConfigData\Datum.yml' -Resolve) 
            $Environment = 'DEV'
            $AllNodes = @($Datum.AllNodes.($Environment).psobject.Properties | ForEach-Object { 
                $Node = $Datum.AllNodes.($Environment).($_.Name)
                $null = $Node.Add('Environment',$Environment)
                if(!$Node.contains('Name') ) {
                    $null = $Node.Add('Name',$_.Name)
                }
                (@{} + $Node)
            })
            
            $ConfigurationData = @{
                AllNodes = $AllNodes
                Datum = $Datum
            }
            $Node = $ConfigurationData.AllNodes[0]
        }

        $TestCases = @(
            @{PropertyPath = 'ExampleProperty1'; ExpectedResult = 'From Node'}
            @{PropertyPath = 'Description';      ExpectedResult = 'This is the DEV environment' }
            @{PropertyPath = 'Shared1\Param1';   ExpectedResult = 'This is the Role override!'}
            @{PropertyPath = 'locationName';     ExpectedResult = 'London'}
            
        )

        It "Datum '<PropertyPath>' for Node $($node.Name) should be '<ExpectedResult>'." -TestCases $TestCases {
            Param($propertyPath,$ExpectedResult)
            Resolve-Datum -searchPaths $Datum.__Definition.ResolutionPrecedence -DatumStructure $datum -PropertyPath $propertyPath -Node $node | Should Be $ExpectedResult
        }

    }
}