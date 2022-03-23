Import-Module -Name datum -Force

InModuleScope -ModuleName Datum {

    $here = $PSScriptRoot
    $projectPath = "$here\..\.." | Convert-Path

    Describe 'Expand-RsopHashtable' {

        $testCases = @(
            @{
                InputObject         = @{
                    Key1 = 'Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
                    Key2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                    Key3 = @(
                        @{
                            SubKey1 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                            SubKey2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                        }
                    )
                }
                IsArrayValue        = $false
                NoSourceInformation = $false
                Depth               = 8
                RelativeFilePath    = 'DscWorkshopConfigData\Datum'
            }
            @{
                InputObject         = @{
                    Key1 = 'Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru
                    Key2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                    Key3 = @(
                        @{
                            SubKey1 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                            SubKey2 = ('Value1' | Add-Member -Name __File -MemberType NoteProperty -Value $projectPath\tests\Integration\assets\DscWorkshopConfigData\Datum.yml -PassThru)
                        }
                    )
                }
                IsArrayValue        = $false
                NoSourceInformation = $true
                Depth               = 8
                RelativeFilePath    = 'DscWorkshopConfigData\Datum'
            }
        )

        It "'Expand-RsopHashtable' returns IDictionary objects'." -TestCases $testCases {
            param ($InputObject, $IsArrayValue, $NoSourceInformation, $Depth)

            $result = Expand-RsopHashtable -InputObject $InputObject -Depth $Depth -IsArrayValue:$IsArrayValue -NoSourceInformation:$NoSourceInformation

            $result | Should -BeOfType [System.Collections.IDictionary]
        }

        It "Items in result end with RelativeFilePath if 'NoSourceInformation' is set to '<NoSourceInformation>'." -TestCases $testCases {
            param ($InputObject, $IsArrayValue, $NoSourceInformation, $Depth, $RelativeFilePath)

            $result = Expand-RsopHashtable -InputObject $InputObject -Depth $Depth -IsArrayValue:$IsArrayValue -NoSourceInformation:$NoSourceInformation
            foreach ($key in $result.Keys)
            {
                if ($result.$key -isnot [array] -and $result.$key -isnot [System.Collections.IDictionary])
                {
                    if ($NoSourceInformation)
                    {
                        $result.$key | Should -Not -BeLike "*$RelativeFilePath"
                    }
                    else
                    {
                        $result.$key | Should -BeLike "*$RelativeFilePath"
                    }
                }
            }
        }

    }

}
