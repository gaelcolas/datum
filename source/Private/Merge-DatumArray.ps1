function Merge-DatumArray
{
    [OutputType([System.Collections.ArrayList])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $ReferenceArray,

        [Parameter(Mandatory = $true)]
        [object]
        $DifferenceArray,

        [Parameter()]
        [hashtable]
        $Strategy = @{},

        [Parameter()]
        [hashtable]
        $ChildStrategies = @{
            '^.*' = $Strategy
        },

        [Parameter(Mandatory = $true)]
        [string]
        $StartingPath
    )

    Write-Debug -Message "`tMerge-DatumArray -StartingPath <$StartingPath>"
    $hashArrayStrategy = $Strategy.merge_hash_array
    Write-Debug -Message "`t`tHash Array Strategy: $hashArrayStrategy"
    $mergeBasetypeArraysStrategy = $Strategy.merge_basetype_array
    $mergedArray = [System.Collections.ArrayList]::new()

    $sortParams = @{}
    if ($propertyNames = [string[]]$Strategy.merge_options.tuple_keys)
    {
        $sortParams.Add('Property', $propertyNames)
    }

    if ($ReferenceArray -as [hashtable[]])
    {
        Write-Debug -Message "`t`tMERGING Array of Hashtables"
        if (-not $hashArrayStrategy -or $hashArrayStrategy -match 'MostSpecific')
        {
            Write-Debug -Message "`t`tMerge_hash_arrays Disabled. value: $hashArrayStrategy"
            $mergedArray = $ReferenceArray
            if ($Strategy.sort_merged_arrays)
            {
                $mergedArray = $mergedArray | Sort-Object @sortParams
            }
            return $mergedArray
        }

        $knockedOutTupleKeyValues = [System.Collections.ArrayList]@()
        foreach ($referenceItem in $ReferenceArray)
        {
            $currentRefItem = [ordered]@{} + $referenceItem

            # make sure property values are converted before merge
            $result = $null
            foreach ($prop in $propertyNames.Where{ $currentRefItem.Contains($_) })
            {
                if (Invoke-DatumHandler -InputObject $currentRefItem[$prop] -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
                {
                    $currentRefItem[$prop] = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
                }
            }

            if ($knockoutPrefixMatcher = $Strategy.merge_options.knockout_prefix)
            {
                $knockoutPrefixMatcher = [regex]::Escape($Strategy.merge_options.knockout_prefix).Insert(0, '^')

                if ($tupleKeyNames = [string[]]$strategy.merge_options.tuple_keys)
                {
                    if ($currentRefItemKeysWithKnockOutValues = $currentRefItem.Keys.Where{ $_ -in $tupleKeyNames -and $currentRefItem[$_] -match $knockoutPrefixMatcher })
                    {
                        $ht = @{}
                        foreach ($key in $currentRefItemKeysWithKnockOutValues)
                        {
                            $ht.$key = $currentRefItem.$key -replace $knockoutPrefixMatcher
                        }

                        $null = $knockedOutTupleKeyValues.Add($ht)
                    }
                }
            }
        }

        switch -Regex ($hashArrayStrategy)
        {
            '^Sum|^Add'
            {
                foreach ($referenceItem in $ReferenceArray)
                {
                    $null = $mergedArray.Add(([ordered]@{} + $referenceItem))
                }
                foreach ($differenceItem in $DifferenceArray)
                {
                    $null = $mergedArray.Add(([ordered]@{} + $differenceItem))
                }
            }

            # MergeHashesByProperties
            '^Deep|^Merge'
            {
                Write-Debug -Message "`t`t`tStrategy for Array Items: Merge Hash By tuple`r`n"
                # look at each $RefItems in $RefArray
                #   if no PropertyNames defined, use all Properties of $RefItem
                #   else use defined propertyNames
                #  Search for DiffItem that has the same Property/Value pairs
                #    if found, Merge-Datum (or MergeHashtable?)
                #    if not found, add $DiffItem to $RefArray

                # look at each $RefItems in $RefArray
                $usedOrKnockedOutDiffItems = [System.Collections.ArrayList]@()
                foreach ($referenceItem in $ReferenceArray)
                {
                    $referenceItem = [ordered]@{} + $referenceItem
                    Write-Debug -Message "`t`t`t  .. Working on Merged Element $($mergedArray.Count)`r`n"
                    # if no PropertyNames defined, use all Properties of $RefItem
                    if (-not $propertyNames)
                    {
                        Write-Debug -Message "`t`t`t ..No PropertyName defined: Use ReferenceItem Keys"
                        $propertyNames = $referenceItem.Keys
                    }
                    $mergedItem = @{} + $referenceItem
                    $diffItemsToMerge = $DifferenceArray.Where{
                        $differenceItem = [ordered]@{} + $_
                        # make sure property values are converted before merge
                        $result = $null
                        foreach ($prop in $propertyNames)
                        {
                            if ($differenceItem.Contains($prop))
                            {
                                if (Invoke-DatumHandler -InputObject $differenceItem.$prop -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
                                {
                                    $differenceItem.$prop = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
                                }
                            }
                        }
                        $itemKnockedOut = $false
                        foreach ($knockedOutTupleKeyValue in $knockedOutTupleKeyValues)
                        {
                            $filterStrings = foreach ($knockedOutTupleKeyValueKey in $knockedOutTupleKeyValue.Keys)
                            {
                                "`$knockedOutTupleKeyValue.'$knockedOutTupleKeyValueKey' -eq `$differenceItem.'$knockedOutTupleKeyValueKey'"
                            }
                            $filterScript = [scriptblock]::Create($filterStrings -join ' -and ')
                            if ( &$filterScript )
                            {
                                $null = $usedOrKnockedOutDiffItems.Add($_)
                                $itemKnockedOut = $true
                                break
                            }
                        }
                        if ($itemKnockedOut -eq $false)
                        {
                            # Search for DiffItem that has the same Property/Value pairs than RefItem
                            $compareHashParams = @{
                                ReferenceHashtable  = [ordered]@{} + $referenceItem
                                DifferenceHashtable = $differenceItem
                                Property            = $propertyNames
                            }
                            (-not (Compare-Hashtable @compareHashParams))
                        }
                    }
                    Write-Debug -Message "`t`t`t ..Items to merge: $($diffItemsToMerge.Count)"
                    $diffItemsToMerge | ForEach-Object {
                        $mergeItemsParams = @{
                            ParentPath          = $StartingPath
                            Strategy            = $Strategy
                            ReferenceHashtable  = $mergedItem
                            DifferenceHashtable = $_
                            ChildStrategies     = $ChildStrategies
                        }
                        $mergedItem = Merge-Hashtable @mergeItemsParams
                    }
                    # If a diff Item has been used, save it to find the unused ones
                    $null = $usedOrKnockedOutDiffItems.AddRange($diffItemsToMerge)
                    $null = $mergedArray.Add($mergedItem)
                }
                $unMergedItems = $DifferenceArray | ForEach-Object {
                    if (-not $usedOrKnockedOutDiffItems.Contains($_))
                    {
                        ([ordered]@{} + $_)
                    }
                }
                if ($null -ne $unMergedItems)
                {
                    if ($unMergedItems -is [System.Array])
                    {
                        $null = $mergedArray.AddRange($unMergedItems)
                    }
                    else
                    {
                        $null = $mergedArray.Add($unMergedItems)
                    }
                }
            }

            # UniqueByProperties
            '^Unique'
            {
                Write-Debug -Message "`t`t`tSelecting Unique Hashes accross both arrays based on Property tuples"
                # look at each $DiffItems in $DiffArray
                #   if no PropertyNames defined, use all Properties of $DiffItem
                #   else use defined PropertyNames
                #  Search for a RefItem that has the same Property/Value pairs
                #  if Nothing is found
                #    add current DiffItem to RefArray

                if (-not $propertyNames)
                {
                    Write-Debug -Message "`t`t`t ..No PropertyName defined: Use ReferenceItem Keys"
                    $propertyNames = $referenceItem.Keys
                }

                $mergedArray = [System.Collections.ArrayList]::new()
                $ReferenceArray | ForEach-Object {
                    $currentRefItem = [ordered]@{} + $_
                    # make sure property values are converted before merge
                    $result = $null
                    foreach ($prop in $propertyNames)
                    {
                        if ($currentRefItem.Contains($prop))
                        {
                            if (Invoke-DatumHandler -InputObject $currentRefItem.$prop -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
                            {
                                $currentRefItem.$prop = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
                            }
                        }
                    }
                    if (-not ($mergedArray.Where{ -not (Compare-Hashtable -Property $propertyNames -ReferenceHashtable $currentRefItem -DifferenceHashtable $_ ) }))
                    {
                        $null = $mergedArray.Add(([ordered]@{} + $_))
                    }
                }

                $DifferenceArray | ForEach-Object {
                    $currentDiffItem = [ordered]@{} + $_
                    # make sure property values are converted before merge
                    $result = $null
                    foreach ($prop in $propertyNames)
                    {
                        if ($currentDiffItem.Contains($prop))
                        {
                            if (Invoke-DatumHandler -InputObject $currentDiffItem.$prop -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result))
                            {
                                $currentDiffItem.$prop = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
                            }
                        }
                    }
                    $itemKnockedOut = $false
                    foreach ($knockedOutTupleKeyValue in $knockedOutTupleKeyValues)
                    {
                        $filterStrings = foreach ($knockedOutTupleKeyValueKey in $knockedOutTupleKeyValue.Keys)
                        {
                            "`$knockedOutTupleKeyValue.'$knockedOutTupleKeyValueKey' -eq `$currentDiffItem.'$knockedOutTupleKeyValueKey'"
                        }
                        $filterScript = [scriptblock]::Create($filterStrings -join ' -and ')
                        if ( &$filterScript )
                        {
                            $itemKnockedOut = $true
                            break
                        }
                    }
                    if ($itemKnockedOut -eq $false)
                    {
                        if (-not ($mergedArray.Where{ -not (Compare-Hashtable -Property $propertyNames -ReferenceHashtable $currentDiffItem -DifferenceHashtable $_ ) }))
                        {
                            $null = $mergedArray.Add(([ordered]@{} + $_))
                        }
                    }
                }
            }
        }
    }

    return (, $mergedArray)
}
