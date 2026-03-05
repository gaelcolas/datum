using module datum

Remove-Module -Name datum

Describe 'Deep structure ConvertTo-Json warning (Issue #136)' {
    BeforeAll {
        $here = $PSScriptRoot
        Import-Module -Name datum

        $datum = New-DatumStructure -DefinitionFile (Join-Path -Path $here -ChildPath 'assets\DeepStructureTestData\Datum.yml')
        $allNodes = $datum.AllNodes.psobject.Properties | ForEach-Object {
            $node = $Datum.AllNodes.($_.Name)
            (@{} + $Node)
        }

        $global:configurationData = @{
            AllNodes = $allNodes
            Datum    = $datum
        }
    }

    Context 'Resolving deep structures should not produce warnings' {

        # Issue #136: ConvertTo-Json defaults to depth 2. Functions like Merge-Datum
        # and Merge-Hashtable use ConvertTo-Json inside Write-Debug/Write-Verbose string
        # interpolation. PowerShell evaluates the expression before checking the stream
        # preference, so the truncation warning is emitted unconditionally.
        # The depth is now configurable via default_json_depth in Datum.yml (default: 4).

        It 'Resolve-NodeProperty should not produce ConvertTo-Json truncation warnings for deep properties' {
            # Use 3>&1 to reliably capture warnings from all nested scopes
            $allOutput = Resolve-NodeProperty -PropertyPath 'DeepConfig' -Node ($AllNodes | Where-Object NodeName -EQ 'TestNode01') 3>&1
            $truncationWarnings = @($allOutput | Where-Object {
                    $_ -is [System.Management.Automation.WarningRecord] -and
                    $_.Message -match 'truncat|depth'
                })
            $truncationWarnings | Should -BeNullOrEmpty -Because 'ConvertTo-Json should use sufficient depth to avoid truncation warnings (Issue #136)'
        }

        It 'Merge-Datum should not produce ConvertTo-Json truncation warnings for deep hashtables' {
            # Directly invoke Merge-Datum with deep hashtables to isolate the merge path.
            $reference = [ordered]@{
                Level1 = [ordered]@{
                    Level2 = [ordered]@{
                        Level3 = [ordered]@{
                            Value = 'refValue'
                        }
                    }
                }
            }
            $difference = [ordered]@{
                Level1 = [ordered]@{
                    Level2 = [ordered]@{
                        Level3 = [ordered]@{
                            Other = 'diffValue'
                        }
                    }
                }
            }
            $strategies = @{
                '^.*' = @{
                    merge_hash           = 'deep'
                    merge_baseType_array = 'MostSpecific'
                    merge_hash_array     = 'MostSpecific'
                    merge_options        = @{
                        knockout_prefix = '--'
                    }
                }
            }

            $allOutput = Merge-Datum -StartingPath 'test' -ReferenceDatum $reference -DifferenceDatum $difference -Strategies $strategies 3>&1
            $truncationWarnings = @($allOutput | Where-Object {
                    $_ -is [System.Management.Automation.WarningRecord] -and
                    $_.Message -match 'truncat|depth'
                })
            $truncationWarnings | Should -BeNullOrEmpty -Because 'ConvertTo-Json should use sufficient depth to avoid truncation warnings (Issue #136)'
        }

        It 'Get-DatumRsop should not produce ConvertTo-Json truncation warnings for deep structures' {
            $allOutput = Get-DatumRsop -Datum $Datum -AllNodes $AllNodes 3>&1
            $truncationWarnings = @($allOutput | Where-Object {
                    $_ -is [System.Management.Automation.WarningRecord] -and
                    $_.Message -match 'truncat|depth'
                })
            $truncationWarnings | Should -BeNullOrEmpty -Because 'ConvertTo-Json should use sufficient depth to avoid truncation warnings (Issue #136)'
        }
    }

    Context 'Configurable default_json_depth' {

        It 'Should use the default_json_depth from Datum.yml when set' {
            $datum.__Definition.default_json_depth | Should -Be 8 -Because 'Datum.yml sets default_json_depth to 8'
        }

        It 'Should not produce truncation warnings for very deep structures when default_json_depth is high enough' {
            # With default_json_depth: 8 in Datum.yml, 5-level deep data should be no problem.
            $reference = [ordered]@{
                A = [ordered]@{
                    B = [ordered]@{
                        C = [ordered]@{
                            D = [ordered]@{
                                E = [ordered]@{
                                    Value = 'deep-ref'
                                }
                            }
                        }
                    }
                }
            }
            $difference = [ordered]@{
                A = [ordered]@{
                    B = [ordered]@{
                        C = [ordered]@{
                            D = [ordered]@{
                                E = [ordered]@{
                                    Other = 'deep-diff'
                                }
                            }
                        }
                    }
                }
            }
            $strategies = @{
                '^.*' = @{
                    merge_hash           = 'deep'
                    merge_baseType_array = 'MostSpecific'
                    merge_hash_array     = 'MostSpecific'
                    merge_options        = @{
                        knockout_prefix = '--'
                    }
                }
            }

            $allOutput = Merge-Datum -StartingPath 'test' -ReferenceDatum $reference -DifferenceDatum $difference -Strategies $strategies 3>&1
            $truncationWarnings = @($allOutput | Where-Object {
                    $_ -is [System.Management.Automation.WarningRecord] -and
                    $_.Message -match 'truncat|depth'
                })
            $truncationWarnings | Should -BeNullOrEmpty -Because 'default_json_depth of 8 should handle 5-level deep structures'
        }

        It 'Should default to depth 4 when default_json_depth is not set in Datum.yml' {
            # Temporarily remove the setting to test the default fallback
            $savedDepth = $datum.__Definition.default_json_depth
            $datum.__Definition.Remove('default_json_depth')
            try
            {
                $jsonDepth = if ($datum.__Definition.default_json_depth) { $datum.__Definition.default_json_depth } else { 4 }
                $jsonDepth | Should -Be 4 -Because 'default should be 4 when not configured'
            }
            finally
            {
                $datum.__Definition['default_json_depth'] = $savedDepth
            }
        }
    }

    Context 'Deep structure merge correctness' {

        It 'Should correctly resolve deeply nested node-specific values' {
            $n = $AllNodes | Where-Object NodeName -EQ 'TestNode01'
            $result = Resolve-NodeProperty -PropertyPath 'DeepConfig' -Node $n
            $result.Level1.Level2a.Level3a.Level4a.Setting1 | Should -Be 'nodeValue1' -Because 'node-specific value should take precedence'
            $result.Level1.Level2a.Level3a.Level4a.Setting2 | Should -Be 'nodeValue2' -Because 'node-specific value should be preserved'
        }

        It 'Should merge baseline values into deep structure' {
            $n = $AllNodes | Where-Object NodeName -EQ 'TestNode01'
            $result = Resolve-NodeProperty -PropertyPath 'DeepConfig' -Node $n
            $result.Level1.Level2a.Level3a.Level4a.Setting3 | Should -Be 'baseDefault3' -Because 'baseline value should be merged in when not overridden'
            $result.Level1.Level2b.ExtraSetting | Should -Be 'baseExtra' -Because 'baseline-only keys should be merged in'
        }
    }
}
