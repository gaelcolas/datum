Import-Module -Name datum -Force

InModuleScope -ModuleName Datum {

    $here = $PSScriptRoot
    $projectPath = "$here\..\.." | Convert-Path

    Describe 'Get-RsopValueString' {

        $testCases = @(
            @{
                InputString          = 'Hello World' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
                Depth                = 0
                Key                  = 'SomeKey'
                RelativeFilePath     = 'DscWorkshopConfigData\Datum'
                AddSourceInformation = $false
            }
            @{
                InputString          = 'Hello World' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
                Depth                = 0
                Key                  = 'SomeKey'
                RelativeFilePath     = 'DscWorkshopConfigData\Datum'
                AddSourceInformation = $true
            }
        )

        It "Result string for '<InputString>' should match the expectations'." -TestCases $testCases {
            param ($InputString, $Depth, $Key, $IsArrayValue, $AddSourceInformation, $RelativeFilePath)

            $resultString = Get-RsopValueString -InputString $InputString -Key $Key -Depth $Depth -IsArrayValue:$IsArrayValue -AddSourceInformation:$AddSourceInformation
            $resultString | Should -BeLike "$InputString*"
            if ($AddSourceInformation)
            {
                $resultString | Should -BeLike "*$RelativeFilePath"
            }
            else
            {
                $resultString | Should -Not -BeLike "*$RelativeFilePath"
            }

            $resultString | Should -BeOfType [string]
        }

    }

}
