Import-Module -Name datum -Force

InModuleScope -ModuleName Datum {

    $here = $PSScriptRoot
    $script:projectPath = "$here\..\.." | Convert-Path

    Describe 'Copy-Object' {

        $testCases = @(
            @{
                DeepCopyObject = Get-Item -Path $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml
                SourceType     = 'System.IO.FileInfo'
                TargetType     = 'Deserialized.System.IO.FileInfo'
            }
            @{
                DeepCopyObject = Get-Item -Path $projectPath\tests\Integration\assets\DscWorkshopConfigData
                SourceType     = 'System.IO.DirectoryInfo'
                TargetType     = 'Deserialized.System.IO.DirectoryInfo'
            }
        )

        It "TargetType of result object is '<TargetType>'" -TestCases $testCases {
            param ($DeepCopyObject, $SourceType, $TargetType)

            $result = Copy-Object -DeepCopyObject $DeepCopyObject
            $DeepCopyObject -is [System.Type]$SourceType
            ($result | Get-Member).TypeName | Select-Object -Unique | Should -Be $TargetType
        }

        It 'Source and cloned objecct have the same property count' -TestCases $testCases {
            param ($DeepCopyObject, $SourceType, $TargetType)

            $result = Copy-Object -DeepCopyObject $DeepCopyObject

            ($DeepCopyObject | Get-Member -MemberType Properties -Force).Count | Should -Be ($result | Get-Member -MemberType Properties -Force).Count
        }

    }

}
