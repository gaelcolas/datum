function Merge-Hashtable {
    [outputType([hashtable])]
    [cmdletBinding()]
    Param(
        # [hashtable] These should stay ordered
        $ReferenceHashtable,

        # [hashtable] These should stay ordered
        $DifferenceHashtable,

        $Strategy = @{
            merge_hash = 'hash'
            merge_baseType_array = 'MostSpecific'
            merge_hash_array = 'MostSpecific'
            merge_options = @{
                knockout_prefix = '--'
            }
        },
        
        $ChildStrategies = @{},

        [string]
        $ParentPath
    )
    
    Write-Debug "`tMerge-Hashtable -ParentPath <$ParentPath>"
    # Removing Case Sensitivity while keeping ordering
    $ReferenceHashtable  = [ordered]@{} + $ReferenceHashtable
    $DifferenceHashtable = [ordered]@{} + $DifferenceHashtable
    $clonedReference     = [ordered]@{} + $ReferenceHashtable

    if ($Strategy.merge_options.knockout_prefix) {
        $KnockoutPrefix = $Strategy.merge_options.knockout_prefix
        $KnockoutPrefixMatcher = [regex]::escape($KnockoutPrefix).insert(0,'^')
    }
    else {
        $KnockoutPrefixMatcher = [regex]::escape('--').insert(0,'^')
    }
    Write-Debug "`t  Knockout Prefix Matcher: $knockoutPrefixMatcher"

    $knockedOutKeys = $ReferenceHashtable.keys.where{$_ -match $KnockoutPrefixMatcher}.foreach{$_ -replace $KnockoutPrefixMatcher} 
    Write-Debug "`t  Knockedout Keys: [$($knockedOutKeys -join ', ')] from reference Hashtable Keys [$($ReferenceHashtable.keys -join ', ')]"

    foreach ($currentKey in $DifferenceHashtable.keys) {
        Write-Debug "`t  CurrentKey: $currentKey"
        if($currentKey -in $knockedOutKeys) {
            Write-Debug "`t`tThe Key $currentkey is knocked out from the reference Hashtable."
        }
        elseif ($currentKey -match $KnockoutPrefixMatcher -and !$ReferenceHashtable.contains(($currentKey -replace $KnockoutPrefixMatcher))) {
            # it's a knockout coming from a lower level key, it should only apply down from here
            Write-Debug "`t`tKnockout prefix found for $currentKey in Difference hashtable, and key not set in Reference hashtable"
            if(!$ReferenceHashtable.contains($currentKey)) {
                Write-Debug "`t`t..adding knockout prefixed key for $curretKey to block further merges"
                $clonedReference.add($currentKey,$null)
            }
        }
        elseif (!$ReferenceHashtable.contains($currentKey) )  {
            #if the key does not exist in reference ht, create it using the DiffHt's value
            Write-Debug "`t    Added Missing Key $currentKey of value: $($DifferenceHashtable[$currentKey]) from difference HT"
            $clonedReference.add($currentKey,$DifferenceHashtable[$currentKey])
        }
        else { #the key exists, and it's not a knockout entry
            $RefHashItemValueType  = Get-DatumType $ReferenceHashtable[$currentKey]
            $DiffHashItemValueType = Get-DatumType $DifferenceHashtable[$currentKey]
            Write-Debug "for Key $currentKey REF:[$RefHashItemValueType] | DIFF:[$DiffHashItemValueType]"
            if($ParentPath) {
                $ChildPath = (Join-Path  $ParentPath $currentKey)
            }
            else {
                $ChildPath = $currentKey
            }

            switch ($RefHashItemValueType) {
                'hashtable'      {
                    if($Strategy.merge_hash -eq 'deep') {
                        Write-Debug "`t`t .. Merging Datums at current path $ChildPath"
                        # if there's no Merge override for the subkey's path in the (not subkeys), 
                        #   merge HASHTABLE with same strategy
                        # otherwise, merge Datum
                        $ChildStrategy = Get-MergeStrategyFromPath -Strategies $ChildStrategies -PropertyPath $ChildPath
                        
                        if($ChildStrategy.Default) {
                            Write-Debug "`t`t ..Merging using the current Deep Strategy, Bypassing default"
                            $MergePerDefault = @{
                                ParentPath = $ChildPath
                                Strategy = $Strategy
                                ReferenceHashtable = $ReferenceHashtable[$currentKey]
                                DifferenceHashtable = $DifferenceHashtable[$currentKey]
                                ChildStrategies = $ChildStrategies
                            }
                            $subMerge = Merge-Hashtable @MergePerDefault
                        }
                        else {
                            Write-Debug "`t`t ..Merging using Override Strategy $($ChildStrategy|ConvertTo-Json)"
                            $MergeDatumParam = @{
                                StartingPath = $ChildPath
                                ReferenceDatum = $ReferenceHashtable[$currentKey]
                                DifferenceDatum = $DifferenceHashtable[$currentKey] 
                                Strategies = $ChildStrategies
                            }
                            $subMerge = Merge-Datum @MergeDatumParam
                        }
                        Write-Debug "`t  # Submerge $($submerge|ConvertTo-Json)."
                        $clonedReference[$currentKey]  = $subMerge
                    }
                }

                'baseType'       {
                    #do nothing to use most specific value (quicker than default)
                }
                
                # Default used for hash_array, baseType_array
                Default {
                    Write-Debug "`t  .. Merging Datums at current path $ChildPath`r`n$($Strategy|ConvertTo-Json)"
                    $MergeDatumParams = @{
                        StartingPath = $ChildPath
                        Strategies = $ChildStrategies
                        ReferenceDatum = $ReferenceHashtable[$currentKey]
                        DifferenceDatum = $DifferenceHashtable[$currentKey]
                    }

                    $clonedReference[$currentKey]  = Merge-Datum @MergeDatumParams
                    Write-Debug "`t  .. Datum Merged for path $ChildPath"
                }
            }
        }
    }

    return $clonedReference
}
