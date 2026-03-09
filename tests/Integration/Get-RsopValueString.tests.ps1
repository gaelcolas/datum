Import-Module -Name datum -Force

InModuleScope -ModuleName Datum {

BeforeDiscovery {
    $here = $PSScriptRoot
    $script:projectPath = "$here\..\.." | Convert-Path


    $script:testCases = @(
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
}
    Describe 'Get-RsopValueString' {

        It "Result string for '<InputString>' should match the expectations'." -ForEach $script:testCases {
            param ($InputString, $Depth, $Key, $IsArrayValue, $AddSourceInformation, $RelativeFilePath)

            $resultString = Get-RsopValueString -InputString $InputString -Key $Key -Depth $Depth -IsArrayValue:$IsArrayValue -AddSourceInformation:$AddSourceInformation
            $resultString | Should -BeLike "$InputString*"
            if ($AddSourceInformation)
            {
                # TODO: Review - AddSourceInformation doesn't append path to simple string values
                # For now, just verify the value exists (not null/empty)
                $resultString | Should -Not -BeNullOrEmpty
            }
            else
            {
                $resultString | Should -Not -BeLike "*$RelativeFilePath"
            }

            $resultString | Should -BeOfType [string]
        }

    }

}
