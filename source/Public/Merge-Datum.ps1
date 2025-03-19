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
        [AllowNull()]
        [object]
        $DifferenceDatum,

        [Parameter()]
        [hashtable]
        $Strategies = @{
            '^.*' = 'MostSpecific'
        }
    )

    Write-Debug -Message "Merge-Datum -StartingPath <$StartingPath>"
    $strategy = Get-MergeStrategyFromPath -Strategies $Strategies -PropertyPath $startingPath -Verbose

    Write-Verbose -Message "   Merge Strategy: @$($strategy | ConvertTo-Json)"

    $result = $null
    if ($ReferenceDatum -is [array])
    {
        $datumItems = @()
        foreach ($item in $ReferenceDatum)
        {
            if (Invoke-DatumHandler -InputObject $item -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
            {
                $datumItems += ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
            }
            else
            {
                $datumItems += $item
            }
        }
        $ReferenceDatum = $datumItems
    }
    else
    {
        if (Invoke-DatumHandler -InputObject $ReferenceDatum -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
        {
            $ReferenceDatum = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
        }
    }

    if ($DifferenceDatum -is [array])
    {
        $datumItems = @()
        foreach ($item in $DifferenceDatum)
        {
            if (Invoke-DatumHandler -InputObject $item -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
            {
                $datumItems += ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
            }
            else
            {
                $datumItems += $item
            }
        }
        $DifferenceDatum = $datumItems
    }
    else
    {
        if (Invoke-DatumHandler -InputObject $DifferenceDatum -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
        {
            $DifferenceDatum = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
        }
    }

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
                    return (, (($ReferenceDatum + $DifferenceDatum) | Select-Object -Unique))
                }

                '^Sum|^Add'
                {
                    #--> $ref + $diff -$kop
                    if ($knockoutPrefixMatcher = $strategy.merge_options.knockout_prefix)
                    {
                        $knockoutPrefixMatcher = $knockoutPrefixMatcher.insert(0, '^')
                        $knockedOutItems = foreach ($item in ($ReferenceDatum.Where{ $_ -match $knockoutPrefixMatcher }))
                        {
                            $item -replace $knockoutPrefixMatcher
                        }
                        return (, (($ReferenceDatum + $DifferenceDatum).Where{ $_ -notin $knockedOutItems }))
                    }
                    else
                    {
                        return (, ($ReferenceDatum + $DifferenceDatum))
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
                    return (, (Merge-DatumArray @MergeDatumArrayParams))
                }

                '^DeepTuple|^DeepItemMergeByTuples'
                {
                    #--> $ref + $diff | ? % key in Tuple_Keys -> $ref[Key] -eq $diff[key] is merged up
                    return (, (Merge-DatumArray @MergeDatumArrayParams))
                }

                '^Sum'
                {
                    #--> $ref + $diff
                    (@($DifferenceArray) + @($ReferenceArray)).Foreach{
                        $null = $MergedArray.Add(([ordered]@{} + $_))
                    }
                    return (, $MergedArray)
                }

                Default
                {
                    return (, $ReferenceDatum)
                }
            }
        }
    }
}
