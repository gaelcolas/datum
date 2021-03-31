function Merge-Hashtable
{
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        # [hashtable] These should stay ordered
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ReferenceHashtable,

        # [hashtable] These should stay ordered
        [Parameter(Mandatory = $true)]
        [hashtable]
        $DifferenceHashtable,

        [Parameter()]
        $Strategy = @{
            merge_hash           = 'hash'
            merge_baseType_array = 'MostSpecific'
            merge_hash_array     = 'MostSpecific'
            merge_options        = @{
                knockout_prefix = '--'
            }
        },

        [Parameter()]
        [hashtable]
        $ChildStrategies = @{},

        [Parameter()]
        [string]
        $ParentPath
    )

    Write-Debug -Message "`tMerge-Hashtable -ParentPath <$ParentPath>"

    # Removing Case Sensitivity while keeping ordering
    $ReferenceHashtable = [ordered]@{} + $ReferenceHashtable
    $DifferenceHashtable = [ordered]@{} + $DifferenceHashtable
    $clonedReference = [ordered]@{} + $ReferenceHashtable

    if ($Strategy.merge_options.knockout_prefix)
    {
        $knockoutPrefix = $Strategy.merge_options.knockout_prefix
        $knockoutPrefixMatcher = [regex]::Escape($knockoutPrefix).Insert(0, '^')
    }
    else
    {
        $knockoutPrefixMatcher = [regex]::Escape('--').insert(0, '^')
    }
    Write-Debug -Message "`t  Knockout Prefix Matcher: $knockoutPrefixMatcher"

    $knockedOutKeys = $ReferenceHashtable.Keys.Where{ $_ -match $knockoutPrefixMatcher }.ForEach{ $_ -replace $knockoutPrefixMatcher }
    Write-Debug -Message "`t  Knockedout Keys: [$($knockedOutKeys -join ', ')] from reference Hashtable Keys [$($ReferenceHashtable.keys -join ', ')]"

    foreach ($currentKey in $DifferenceHashtable.keys)
    {
        Write-Debug -Message "`t  CurrentKey: $currentKey"
        if ($currentKey -in $knockedOutKeys)
        {
            Write-Debug -Message "`t`tThe Key $currentkey is knocked out from the reference Hashtable."
        }
        elseif ($currentKey -match $knockoutPrefixMatcher -and -not $ReferenceHashtable.Contains(($currentKey -replace $knockoutPrefixMatcher)))
        {
            # it's a knockout coming from a lower level key, it should only apply down from here
            Write-Debug -Message "`t`tKnockout prefix found for $currentKey in Difference hashtable, and key not set in Reference hashtable"
            if (-not $ReferenceHashtable.Contains($currentKey))
            {
                Write-Debug -Message "`t`t..adding knockout prefixed key for $curretKey to block further merges"
                $clonedReference.Add($currentKey, $null)
            }
        }
        elseif (-not $ReferenceHashtable.Contains($currentKey) )
        {
            #if the key does not exist in reference ht, create it using the DiffHt's value
            Write-Debug -Message "`t    Added Missing Key $currentKey of value: $($DifferenceHashtable[$currentKey]) from difference HT"
            $clonedReference.Add($currentKey, $DifferenceHashtable[$currentKey])
        }
        else
        {
            #the key exists, and it's not a knockout entry
            $refHashItemValueType = Get-DatumType -DatumObject $ReferenceHashtable[$currentKey]
            $diffHashItemValueType = Get-DatumType -DatumObject $DifferenceHashtable[$currentKey]
            Write-Debug -Message "for Key $currentKey REF:[$refHashItemValueType] | DIFF:[$diffHashItemValueType]"
            if ($ParentPath)
            {
                $childPath = Join-Path -Path $ParentPath -ChildPath $currentKey
            }
            else
            {
                $childPath = $currentKey
            }

            switch ($refHashItemValueType)
            {
                'hashtable'
                {
                    if ($Strategy.merge_hash -eq 'deep')
                    {
                        Write-Debug -Message "`t`t .. Merging Datums at current path $childPath"
                        # if there's no Merge override for the subkey's path in the (not subkeys),
                        #   merge HASHTABLE with same strategy
                        # otherwise, merge Datum
                        $childStrategy = Get-MergeStrategyFromPath -Strategies $ChildStrategies -PropertyPath $childPath

                        if ($childStrategy.Default)
                        {
                            Write-Debug -Message "`t`t ..Merging using the current Deep Strategy, Bypassing default"
                            $MergePerDefault = @{
                                ParentPath          = $childPath
                                Strategy            = $Strategy
                                ReferenceHashtable  = $ReferenceHashtable[$currentKey]
                                DifferenceHashtable = $DifferenceHashtable[$currentKey]
                                ChildStrategies     = $ChildStrategies
                            }
                            $subMerge = Merge-Hashtable @MergePerDefault
                        }
                        else
                        {
                            Write-Debug -Message "`t`t ..Merging using Override Strategy $($childStrategy | ConvertTo-Json)"
                            $MergeDatumParam = @{
                                StartingPath    = $childPath
                                ReferenceDatum  = $ReferenceHashtable[$currentKey]
                                DifferenceDatum = $DifferenceHashtable[$currentKey]
                                Strategies      = $ChildStrategies
                            }
                            $subMerge = Merge-Datum @MergeDatumParam
                        }
                        Write-Debug -Message "`t  # Submerge $($submerge|ConvertTo-Json)."
                        $clonedReference[$currentKey] = $subMerge
                    }
                }

                'baseType'
                {
                    #do nothing to use most specific value (quicker than default)
                }

                # Default used for hash_array, baseType_array
                default
                {
                    Write-Debug -Message "`t  .. Merging Datums at current path $childPath`r`n$($Strategy | ConvertTo-Json)"
                    $MergeDatumParams = @{
                        StartingPath    = $childPath
                        Strategies      = $ChildStrategies
                        ReferenceDatum  = $ReferenceHashtable[$currentKey]
                        DifferenceDatum = $DifferenceHashtable[$currentKey]
                    }

                    if ($clonedReference.$currentKey -is [System.Array])
                    {
                        [System.Array]$clonedReference[$currentKey] = Merge-Datum @MergeDatumParams
                    }
                    else
                    {
                        $clonedReference[$currentKey] = Merge-Datum @MergeDatumParams
                    }
                    Write-Debug -Message "`t  .. Datum Merged for path $childPath"
                }
            }
        }
    }

    return $clonedReference
}
