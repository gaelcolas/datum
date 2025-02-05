function Clear-DatumKnockout
{
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $StartingPath,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]
        $ReferenceDatum,

        [Parameter()]
        [hashtable]
        $Strategies = @{
            '^.*' = 'MostSpecific'
        }
    )

    Write-Debug -Message "Clear-DatumKnockout -StartingPath <$StartingPath>"
    $strategy = Get-MergeStrategyFromPath -Strategies $Strategies -PropertyPath $startingPath -Verbose

    $result = $null

    $referenceDatumType = Get-DatumType -DatumObject $ReferenceDatum

    if ($strategy -is [string])
    {
        $strategy = Get-MergeStrategyFromString -MergeStrategy $strategy
    }

    Write-Verbose -Message "   Knockout-Prefix: $($strategy.merge_options.knockout_prefix)"

    switch ($referenceDatumType)
    {
        'hashtable'
        {
            if ($strategy.merge_hash -match '^MostSpecific$|^First')
            {
                return $ReferenceDatum
            }

            $clonedReference = [ordered]@{} + $ReferenceDatum

            if ($knockoutPrefixMatcher = $strategy.merge_options.knockout_prefix)
            {
                foreach ($knockoutKey in ($ReferenceDatum.Keys.Where{ $_ -match $knockoutPrefixMatcher }))
                {
                    $clonedReference.Remove($knockoutKey)
                }
            }

            $cleanedReference = [ordered]@{} + $clonedReference

            foreach ($currentKey in $clonedReference.Keys)
            {
                $refHashItemValueType = Get-DatumType -DatumObject $clonedReference[$currentKey]

                if ($refHashItemValueType -ne 'baseType')
                {
                    $cleanupParams = @{
                        StartingPath   = Join-Path -Path $StartingPath -ChildPath $currentKey
                        ReferenceDatum = $ReferenceDatum[$currentKey]
                        Strategies     = $Strategies
                    }
                    $cleanedReference[$currentKey] = Clear-DatumKnockout @cleanupParams
                }
            }

            return $cleanedReference
        }

        'baseType_array'
        {
            if ($strategy.merge_baseType_array -match '^MostSpecific$|^First')
            {
                return $ReferenceDatum
            }

            if ($knockoutPrefixMatcher = $strategy.merge_options.knockout_prefix)
            {
                $knockoutPrefixMatcher = $knockoutPrefixMatcher.insert(0, '^')
                return (, ($ReferenceDatum.Where{ $_ -notmatch $knockoutPrefixMatcher }))
            }
            else
            {
                return $ReferenceDatum
            }
        }

        'hash_array'
        {
            if ($strategy.merge_hash_array -match '^MostSpecific$|^First')
            {
                return $ReferenceDatum
            }

            if ($knockoutPrefixMatcher = $strategy.merge_options.knockout_prefix)
            {
                if ($tupleKeyNames = [string[]]$Strategy.merge_options.tuple_keys)
                {
                    $knockoutItems = foreach ($refItem in $ReferenceDatum)
                    {
                        $refItemTupleKeys = $refItem.Keys.Where{ $_ -in $tupleKeyNames }
                        if ($refItemTupleKeys -match $knockoutPrefixMatcher)
                        {
                            $refItem
                        }
                    }
                    foreach ($knockoutItem in $knockoutItems)
                    {
                        $ReferenceDatum.Remove($knockoutItem)
                    }
                }
            }

            $cleanedArray = [System.Collections.ArrayList]::new()

            foreach ($currentItem in $ReferenceDatum)
            {
                $cleanupItemParams = @{
                    StartingPath   = $StartingPath
                    ReferenceDatum = $currentItem
                    Strategies     = $Strategies
                }
                $null = $cleanedArray.Add((Clear-DatumKnockout @cleanupItemParams))
            }

            return (, $cleanedArray)
        }

        default
        {
            return $ReferenceDatum
        }
    }
}
