Import-Module -Name datum -Force

InModuleScope -ModuleName Datum {

    $here = $PSScriptRoot
    $projectPath = "$here\..\.." | Convert-Path

    Describe 'Expand-RsopHashtable' {

        $testCases = @(
            @{
                InputObject          = @{
                    Key1 = 'Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
                    Key2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                    Key3 = @(
                        @{
                            SubKey1 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                            SubKey2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                        }
                    )
                }
                IsArrayValue         = $false
                AddSourceInformation = $false
                Depth                = 8
                RelativeFilePath     = 'DscWorkshopConfigData\Datum'
            }
            @{
                InputObject          = @{
                    Key1 = 'Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
                    Key2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                    Key3 = @(
                        @{
                            SubKey1 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                            SubKey2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                        }
                    )
                }
                IsArrayValue         = $false
                AddSourceInformation = $true
                Depth                = 8
                RelativeFilePath     = 'DscWorkshopConfigData\Datum'
            }
        )

        It "'Expand-RsopHashtable' returns IDictionary objects'." -TestCases $testCases {
            param ($InputObject, $IsArrayValue, $AddSourceInformation, $Depth)

            $result = Expand-RsopHashtable -InputObject $InputObject -Depth $Depth -IsArrayValue:$IsArrayValue -AddSourceInformation:$AddSourceInformation

            $result | Should -BeOfType [System.Collections.IDictionary]
        }

        It "Items in result end with RelativeFilePath if 'AddSourceInformation' is set to '<AddSourceInformation>'." -TestCases $testCases {
            param ($InputObject, $IsArrayValue, $AddSourceInformation, $Depth, $RelativeFilePath)

            $result = Expand-RsopHashtable -InputObject $InputObject -Depth $Depth -IsArrayValue:$IsArrayValue -AddSourceInformation:$AddSourceInformation
            foreach ($key in $result.Keys)
            {
                if ($result.$key -isnot [array] -and $result.$key -isnot [System.Collections.IDictionary])
                {
                    if ($AddSourceInformation)
                    {
                        $result.$key | Should -BeLike "*$RelativeFilePath"
                    }
                    else
                    {
                        $result.$key | Should -Not -BeLike "*$RelativeFilePath"
                    }
                }
            }
        }

    }

}
