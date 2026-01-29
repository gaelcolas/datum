# Pester 5 test for Copy-Object private function
$here = $PSScriptRoot
$projectPath = "$here\..\.." | Convert-Path

Describe 'Copy-Object' {
    BeforeDiscovery {
        # Test case metadata for discovery - just paths, not actual objects
        $script:testCaseMetadata = @(
            @{
                Path = "$projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml"
                SourceType = 'System.IO.FileInfo'
                TargetType = 'Deserialized.System.IO.FileInfo'
            }
            @{
                Path = "$projectPath\tests\Integration\assets\DscWorkshopConfigData"
                SourceType = 'System.IO.DirectoryInfo'
                TargetType = 'Deserialized.System.IO.DirectoryInfo'
            }
        )

        # Build property test cases for discovery
        $script:propertyTests = @()
        foreach ($meta in $script:testCaseMetadata) {
            $tempItem = Get-Item -Path $meta.Path
            $properties = $tempItem | Get-Member -MemberType Properties
            foreach ($prop in $properties) {
                $script:propertyTests += @{
                    Path = $meta.Path
                    Property = $prop.Name
                    SourceType = $meta.SourceType
                }
            }
        }
    }

    BeforeAll {
        # Import module for InModuleScope access
        if (-not (Get-Module -Name datum)) {
            Import-Module -Name datum -Force
        }

        # Build actual test data using InModuleScope
        $script:testResults = @{}

        foreach ($metadata in $testCaseMetadata) {
            $item = Get-Item -Path $metadata.Path

            # Call Copy-Object via InModuleScope
            $result = InModuleScope -ModuleName Datum -Parameters @{ obj = $item } -ScriptBlock {
                param($obj)
                Copy-Object -DeepCopyObject $obj
            }

            $script:testResults[$metadata.Path] = @{
                Item = $item
                Result = $result
            }
        }
    }

    It "TargetType of '<SourceType>' result is '<TargetType>'" -ForEach $script:testCaseMetadata {
        param ($Path, $SourceType, $TargetType)

        $testData = $script:testResults[$Path]
        ($testData.Result | Get-Member).TypeName | Select-Object -Unique | Should -Be $TargetType
    }

    It "Source and cloned '<SourceType>' have same or more properties" -ForEach $script:testCaseMetadata {
        param ($Path, $SourceType, $TargetType)

        $testData = $script:testResults[$Path]
        $sourceCount = ($testData.Item | Get-Member -MemberType Properties).Count
        $resultCount = ($testData.Result | Get-Member -MemberType Properties).Count
        $resultCount | Should -BeGreaterOrEqual $sourceCount
    }

    It "Property '<Property>' of '<Path>' copied correctly" -ForEach $script:propertyTests {
        param ($Path, $Property)

        $testData = $script:testResults[$Path]
        $sourceValue = $testData.Item.($Property) -as [string]
        $resultValue = $testData.Result.($Property) -as [string]
        $resultValue | Should -Be $sourceValue
    }
}
