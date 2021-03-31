function Merge-Datum
{
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $StartingPath,

        [Parameter(Mandatory = $true)]
        [object]
        $ReferenceDatum,

        [Parameter(Mandatory = $true)]
        [object]
        $DifferenceDatum,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $Strategies = @{
            '^.*' = 'MostSpecific'
        }
    )

    Write-Debug -Message "Merge-Datum -StartingPath <$StartingPath>"
    $strategy = Get-MergeStrategyFromPath -Strategies $Strategies -PropertyPath $startingPath -Verbose

    Write-Verbose -Message "   Merge Strategy: @$($strategy | ConvertTo-Json)"

    $referenceDatumType = Get-DatumType -DatumObject $ReferenceDatum
    $differenceDatumType = Get-DatumType -DatumObject $DifferenceDatum

    if ($referenceDatumType -ne $differenceDatumType)
    {
        Write-Warning -Message "Cannot merge different types in path '$StartingPath' REF:[$referenceDatumType] | DIFF:[$differenceDatumType]$($DifferenceDatum.GetType()) , returning most specific Datum."
        return $ReferenceDatum
    }

    if ($strategy -is [string])
    {
        $strategy = Get-MergeStrategyFromString -MergeStrategy $strategy
    }

    switch ($referenceDatumType)
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
                Strategy            = $strategy
                ParentPath          = $StartingPath
                ChildStrategies     = $Strategies
            }

            if ($strategy.merge_hash -match '^MostSpecific$|^First')
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
            switch -Regex ($strategy.merge_baseType_array)
            {
                '^MostSpecific$|^First'
                {
                    return $ReferenceDatum
                }

                '^Unique'
                {
                    if ($regexPattern = $strategy.merge_options.knockout_prefix)
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
                    if ($regexPattern = $strategy.merge_options.knockout_prefix)
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
                Strategy        = $strategy
                ChildStrategies = $Strategies
                StartingPath    = $StartingPath
            }

            switch -Regex ($strategy.merge_hash_array)
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
                        $null = $MergedArray.Add(([ordered]@{} + $_))
                    }
                    , $MergedArray
                }

                Default
                {
                    return , $ReferenceDatum
                }
            }
        }
    }
}
