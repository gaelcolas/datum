using module datum

if ($PSScriptRoot) {
    $here = $PSScriptRoot
}
else {
    $here = Join-Path $pwd.Path '*\tests\Integration\' -Resolve
}
remove-module datum
Write-verbose "Here: $here"

Describe 'Test Datum overrides' {
    Context 'Most specific Merge behavior' {
        BeforeAll {
            import-module datum

            $Datum = New-Datumstructure -DefinitionFile  (Join-path $here '.\assets\Demo3\Datum.yml' -Resolve)

            $AllNodes = @($Datum.AllNodes.psobject.Properties | ForEach-Object {
                $Node = $Datum.AllNodes.($_.Name)
                (@{} + $Node)
            })

            $ConfigurationData = @{
                AllNodes = $AllNodes
                Datum = $Datum
            }
        }

        $TestCases = @(
            @{Node = 'Node1'; PropertyPath = 'Disks'; Count = 1}
            @{Node = 'Node2'; PropertyPath = 'Disks'; Count = 3}

        )

        It "The count of Datum <PropertyPath> for Node <Node> should be '<Count>'." -TestCases $TestCases {
            Param($Node,$PropertyPath,$Count)

            $MyNode = $AllNodes.Where({$_.Name -eq $Node})
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $MyNode -DatumTree $Datum) | Should -HaveCount $Count
        }

        it "should return False as value" {
            $MyNode = $AllNodes.Where( {$_.Name -eq "Node3"})
            lookup -PropertyPath StartVM -Node $MyNode -DatumTree $Datum | Should -BeFalse
        }
    }
}
