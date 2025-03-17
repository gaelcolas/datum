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

        $propertiesTestCases = @()
        foreach ($testCase in $testCases)
        {
            $result = Copy-Object -DeepCopyObject $testCase.DeepCopyObject
            $properties = $testCase.DeepCopyObject | Get-Member -MemberType Properties
            foreach ($property in $properties)
            {
                $propertiesTestCases += @{
                    DeepCopyObject      = $testCase.DeepCopyObject
                    TargetObject        = $result
                    Property            = $property.Name
                    PropertySourceValue = $testCase.DeepCopyObject.$($property.Name)
                    PropertyTargetValue = $result.$($property.Name)
                }
            }
        }

        It "TargetType of result object '<DeepCopyObject>' is '<TargetType>'" -TestCases $testCases {
            param ($DeepCopyObject, $SourceType, $TargetType)

            $result = Copy-Object -DeepCopyObject $DeepCopyObject
            $DeepCopyObject -is [System.Type]$SourceType
            ($result | Get-Member).TypeName | Select-Object -Unique | Should -Be $TargetType
        }

        It "Source '<DeepCopyObject>' and cloned object have the same property count" -TestCases $testCases {
            param ($DeepCopyObject, $SourceType, $TargetType)

            $result = Copy-Object -DeepCopyObject $DeepCopyObject

            ($result | Get-Member -MemberType Properties).Count | Should -BeGreaterThan ($DeepCopyObject | Get-Member -MemberType Properties).Count
        }

        It "Destination object has the property '<Property>' with value '<PropertySourceValue>'" -TestCases $propertiesTestCases {
            param ($DeepCopyObject, $TargetObject, $Property, $PropertySourceValue, $PropertyTargetValue)

            $PropertySourceValue = $PropertySourceValue -as [string]
            $PropertyTargetValue = $PropertyTargetValue -as [string]

            $PropertySourceValue | Should -Be $PropertyTargetValue
        }

    }

}
