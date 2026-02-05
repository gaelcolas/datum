using module datum

$here = $PSScriptRoot

Remove-Module -Name datum

BeforeDiscovery {
    Import-Module -Name datum

    $script:datum = New-DatumStructure -DefinitionFile (Join-Path $here '.\assets\Demo3\datum.yml' -Resolve)

    $script:AllNodes = @($datum.AllNodes.psobject.Properties | ForEach-Object {
            $Node = $datum.AllNodes.($_.Name)
            (@{} + $Node)
        })

    $global:configurationData = @{
        AllNodes = $AllNodes
        datum    = $datum
    }

    $script:testCases = @(
        @{Node = 'Node1'; PropertyPath = 'Disks'; Count = 1 }
        @{Node = 'Node2'; PropertyPath = 'Disks'; Count = 3 }
    )
}

Describe 'Test datum overrides' {
    BeforeAll {
        # Reload module for test execution
        if (Get-Module -Name datum -ErrorAction SilentlyContinue) {
            Remove-Module -Name datum -Force
        }
        Import-Module -Name datum -Force

        $script:datum = New-DatumStructure -DefinitionFile (Join-Path $PSScriptRoot '.\assets\Demo3\datum.yml' -Resolve)
        $script:AllNodes = @($script:datum.AllNodes.psobject.Properties | ForEach-Object {
            $Node = $script:datum.AllNodes.($_.Name)
            (@{} + $Node)
        })
    }

    Context 'Most specific Merge behavior' {

        It "The count of datum <PropertyPath> for Node <Node> should be '<Count>'." -ForEach $script:testCases {
            Param($Node, $PropertyPath, $Count)

            $myNode = $script:AllNodes.Where( { $_.Name -eq $Node })
            (Resolve-NodeProperty -PropertyPath $PropertyPath -Node $myNode -DatumTree $script:datum) | Should -HaveCount $Count
        }

        It 'should return False as value' {
            $myNode = $script:AllNodes.Where( { $_.Name -eq 'Node3' })
            Lookup -PropertyPath StartVM -Node $myNode -DatumTree $script:datum | Should -BeFalse
        }
    }
}
