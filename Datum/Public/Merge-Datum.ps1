function Merge-Datum {
    [CmdletBinding()]
    param (
        [string]
        $StartingPath,

        $ReferenceDatum,

        $DifferenceDatum,

        $Strategies = @{
            '^.*' = 'MostSpecific'
        }
    )

    if ($DifferenceDatum -is [DatumProvider])
    {
        $DifferenceDatum = ConvertTo-Datum -InputObject $DifferenceDatum | Add-Member -Name FlexType -MemberType NoteProperty -Value $StartingPath -PassThru
    }
    
    if ($ReferenceDatum.__DatumInternal_Path -and $DifferenceDatum -is [System.Collections.IEnumerable])
    {
        Write-Verbose "Reference is imported from a file and difference is an array. Converting reference to array to allow merge"
        $ReferenceDatum = @($ReferenceDatum)
    }

    Write-Debug "Merge-Datum -StartingPath <$StartingPath>"
    $Strategy = Get-MergeStrategyFromPath -Strategies $strategies -PropertyPath $startingPath -Verbose

    Write-Verbose "   Merge Strategy: @$($Strategy | ConvertTo-Json)"

    $ReferenceDatumType  = Get-DatumType -DatumObject $ReferenceDatum
    $DifferenceDatumType = Get-DatumType -DatumObject $DifferenceDatum

    if($ReferenceDatumType -ne $DifferenceDatumType) {
        Write-Warning "Cannot merge different types in path '$StartingPath' REF:[$ReferenceDatumType] | DIFF:[$DifferenceDatumType]$($DifferenceDatum.GetType()) , returning most specific Datum."
        return $ReferenceDatum
    }

    if($Strategy -is [string]) {
        $Strategy = Get-MergeStrategyFromString -MergeStrategy $Strategy
    }

    switch ($ReferenceDatumType) {
        'BaseType' {
            return $ReferenceDatum
        }

        'hashtable' {
            $mergeParams = @{
                ReferenceHashtable  = $ReferenceDatum
                DifferenceHashtable = $DifferenceDatum
                Strategy = $Strategy
                ParentPath = $StartingPath
                ChildStrategies = $Strategies
            }

            if($Strategy.merge_hash -match '^MostSpecific$|^First') {
                return $ReferenceDatum
            }
            else {
                Merge-Hashtable @mergeParams
            }
        }

        'baseType_array' {
            switch -Regex ($Strategy.merge_baseType_array) {
                '^MostSpecific$|^First' { return $ReferenceDatum }

                '^Unique'   {
                    if($regexPattern = $Strategy.merge_options.knockout_prefix) {
                        $regexPattern = $regexPattern.insert(0,'^')
                        $result = @(($ReferenceDatum + $DifferenceDatum).Where{$_ -notmatch $regexPattern} | Select-object -Unique)
                        Write-Output $result -NoEnumerate
                    }
                    else {
                        $result = @(($ReferenceDatum + $DifferenceDatum) | Select-Object -Unique)
                        Write-Output $result -NoEnumerate
                    }

                }

                '^Sum|^Add' {
                    #--> $ref + $diff -$kop
                    if($regexPattern = $Strategy.merge_options.knockout_prefix) {
                        $regexPattern = $regexPattern.insert(0,'^')
                        Write-Output (($ReferenceDatum + $DifferenceDatum).Where{$_ -notmatch $regexPattern}) -NoEnumerate
                    }
                    else {
                        Write-Output ($ReferenceDatum + $DifferenceDatum) -NoEnumerate
                    }
                }

                Default { Write-Output $ReferenceDatum -NoEnumerate; return }
            }
        }

        'hash_array' {
            $MergeDatumArrayParams = @{
                ReferenceArray = $ReferenceDatum
                DifferenceArray = $DifferenceDatum
                Strategy = $Strategy
                ChildStrategies = $Strategies
                StartingPath = $StartingPath
            }

            switch -Regex ($Strategy.merge_hash_array) {
                '^MostSpecific|^First' { return $ReferenceDatum }

                '^UniqueKeyValTuples'  {
                    #--> $ref + $diff | ? % key in TupleKeys -> $ref[Key] -eq $diff[key] is not already int output
                    Write-Output (Merge-DatumArray @MergeDatumArrayParams) -NoEnumerate
                }

                '^DeepTuple|^DeepItemMergeByTuples' {
                    #--> $ref + $diff | ? % key in TupleKeys -> $ref[Key] -eq $diff[key] is merged up
                    Write-Output (Merge-DatumArray @MergeDatumArrayParams) -NoEnumerate
                }

                '^Sum' {
                    #--> $ref + $diff
                    (@($DifferenceArray) + @($ReferenceArray)).Foreach{
                        $null = $MergedArray.add(([ordered]@{}+$_))
                    }
                    Write-Output $MergedArray -NoEnumerate
                }

                Default { Write-Output $ReferenceDatum -NoEnumerate; return }
            }
        }
    }
}