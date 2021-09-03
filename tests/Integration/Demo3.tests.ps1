using module datum

$here = $PSScriptRoot

Remove-Module -Name datum

Describe 'Test datum overrides' {

    Context 'Most specific Merge behavior' {

        BeforeAll {
            Import-Module -Name datum

            $datum = New-DatumStructure -DefinitionFile (Join-Path $here '.\assets\Demo3\datum.yml' -Resolve)

            $AllNodes = @($datum.AllNodes.psobject.Properties | ForEach-Object {
                    $Node = $datum.AllNodes.($_.Name)
                    (@{} + $Node)
                })

            $configurationData = @{
                AllNodes = $AllNodes
                datum    = $datum
            }
        }

        $testCases = @(
            @{Node = 'Node1'; PropertyPath = 'Disks'; Count = 1 }
            @{Node = 'Node2'; PropertyPath = 'Disks'; Count = 3 }
        )

        It "The count of datum <PropertyPath> for Node <Node> should be '<Count>'." -TestCases $testCases {
            Param($Node, $PropertyPath, $Count)

            $myNode = $AllNodes.Where( { $_.Name -eq $Node })
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $myNode -DatumTree $datum) | Should -HaveCount $Count
        }

        It 'should return False as value' {
            $myNode = $AllNodes.Where( { $_.Name -eq 'Node3' })
            Lookup -PropertyPath StartVM -Node $myNode -DatumTree $datum | Should -BeFalse
        }
    }
}
