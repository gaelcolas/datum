function Merge-Datum
{
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

    Write-Debug "Merge-Datum -StartingPath <$StartingPath>"
    $Strategy = Get-MergeStrategyFromPath -Strategies $strategies -PropertyPath $startingPath -Verbose

    Write-Verbose "   Merge Strategy: @$($Strategy | ConvertTo-Json)"

    $ReferenceDatumType = Get-DatumType -DatumObject $ReferenceDatum
    $DifferenceDatumType = Get-DatumType -DatumObject $DifferenceDatum

    if ($ReferenceDatumType -ne $DifferenceDatumType)
    {
        Write-Warning "Cannot merge different types in path '$StartingPath' REF:[$ReferenceDatumType] | DIFF:[$DifferenceDatumType]$($DifferenceDatum.GetType()) , returning most specific Datum."
        return $ReferenceDatum
    }

    if ($Strategy -is [string])
    {
        $Strategy = Get-MergeStrategyFromString -MergeStrategy $Strategy
    }

    switch ($ReferenceDatumType)
    {
        'BaseType'
        {
            return $ReferenceDatum
        }

        'hashtable'
        {
            $mergeParams = @{
                ReferenceHashtable  = $ReferenceDatum
                DifferenceHashtable = $DifferenceDatum
                Strategy            = $Strategy
                ParentPath          = $StartingPath
                ChildStrategies     = $Strategies
            }

            if ($Strategy.merge_hash -match '^MostSpecific$|^First')
            {
                return $ReferenceDatum
            }
            else
            {
                Merge-Hashtable @mergeParams
            }
        }

        'baseType_array'
        {
            switch -Regex ($Strategy.merge_baseType_array)
            {
                '^MostSpecific$|^First'
                {
                    return $ReferenceDatum
                }

                '^Unique'
                {
                    if ($regexPattern = $Strategy.merge_options.knockout_prefix)
                    {
                        $regexPattern = $regexPattern.insert(0, '^')
                        $result = @(($ReferenceDatum + $DifferenceDatum).Where{ $_ -notmatch $regexPattern } | Select-Object -Unique)
                        , $result
                    }
                    else
                    {
                        $result = @(($ReferenceDatum + $DifferenceDatum) | Select-Object -Unique)
                        , $result
                    }

                }

                '^Sum|^Add'
                {
                    #--> $ref + $diff -$kop
                    if ($regexPattern = $Strategy.merge_options.knockout_prefix)
                    {
                        $regexPattern = $regexPattern.insert(0, '^')
                        , (($ReferenceDatum + $DifferenceDatum).Where{ $_ -notMatch $regexPattern })
                    }
                    else
                    {
                        , ($ReferenceDatum + $DifferenceDatum)
                    }
                }

                Default
                {
                    return (, $ReferenceDatum)
                }
            }
        }

        'hash_array'
        {
            $MergeDatumArrayParams = @{
                ReferenceArray  = $ReferenceDatum
                DifferenceArray = $DifferenceDatum
                Strategy        = $Strategy
                ChildStrategies = $Strategies
                StartingPath    = $StartingPath
            }

            switch -Regex ($Strategy.merge_hash_array)
            {
                '^MostSpecific|^First'
                {
                    return $ReferenceDatum
                }

                '^UniqueKeyValTuples'
                {
                    #--> $ref + $diff | ? % key in Tuple_Keys -> $ref[Key] -eq $diff[key] is not already int output
                    , (Merge-DatumArray @MergeDatumArrayParams)
                }

                '^DeepTuple|^DeepItemMergeByTuples'
                {
                    #--> $ref + $diff | ? % key in Tuple_Keys -> $ref[Key] -eq $diff[key] is merged up
                    , (Merge-DatumArray @MergeDatumArrayParams)
                }

                '^Sum'
                {
                    #--> $ref + $diff
                    (@($DifferenceArray) + @($ReferenceArray)).Foreach{
                        $null = $MergedArray.add(([ordered]@{} + $_))
                    }
                    , $MergedArray
                }

                Default
                {
                    return (, $ReferenceDatum)
                }
            }
        }
    }
}
