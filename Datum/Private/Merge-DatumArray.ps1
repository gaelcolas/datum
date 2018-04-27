function Merge-DatumArray {
    [CmdletBinding()]
    Param(
        $ReferenceArray,

        $DifferenceArray,

        $Strategy = @{ },

        $ChildStrategies = @{'^.*' = $Strategy},

        $StartingPath
    )
    
    Write-Debug "`tMerge-DatumArray -StartingPath <$StartingPath>"
    $knockout_prefix = [regex]::Escape($Strategy.merge_options.knockout_prefix).insert(0,'^')
    $HashArrayStrategy = $Strategy.merge_hash_array
    Write-Debug "`t`tHash Array Strategy: $HashArrayStrategy"
    $MergeBasetypeArraysStrategy = $Strategy.merge_basetype_array
    $MergedArray = [System.Collections.ArrayList]::new()

    $SortParams = @{}
    if($PropertyNames = [String[]]$Strategy.merge_options.tuple_keys) {
        $SortParams.Add('Property',$PropertyNames)
    }

    if($ReferenceArray -as [hashtable[]]) {
        Write-Debug "`t`tMERGING Array of Hashtables"
        if(!$HashArrayStrategy -or $HashArrayStrategy -match 'MostSpecific') {
            Write-Debug "`t`tMerge_hash_arrays Disabled. value: $HashArrayStrategy"
            $MergedArray = $ReferenceArray
            if($Strategy.sort_merged_arrays) {
                $MergedArray = $MergedArray | Sort-Object @SortParams
            }
            return $MergedArray
        }

        switch -Regex ($HashArrayStrategy) {
            '^Sum|^Add' {
                (@($DifferenceArray) + @($ReferenceArray)).Foreach{
                    $null = $MergedArray.add(([ordered]@{}+$_))
                }
            }
            
            # MergeHashesByProperties
            '^Deep|^Merge' {
                Write-Debug "`t`t`tStrategy for Array Items: Merge Hash By tuple`r`n"
                # look at each $RefItems in $RefArray
                #   if no PropertyNames defined, use all Properties of $RefItem
                #   else use defined propertyNames
                #  Search for DiffItem that has the same Property/Value pairs
                #    if found, Merge-Datum (or MergeHashtable?)
                #    if not found, add $DiffItem to $RefArray

                # look at each $RefItems in $RefArray
                $UsedDiffItems = [System.Collections.ArrayList]::new()
                foreach ($ReferenceItem in $ReferenceArray) {
                    $ReferenceItem = [ordered]@{} + $ReferenceItem
                    Write-Debug "`t`t`t  .. Working on Merged Element $($MergedArray.Count)`r`n"
                    # if no PropertyNames defined, use all Properties of $RefItem
                    if(!$PropertyNames) {
                        Write-Debug "`t`t`t ..No PropertyName defined: Use ReferenceItem Keys"
                        $PropertyNames = $ReferenceItem.Keys
                    }
                    $MergedItem = @{} + $ReferenceItem
                    $DiffItemsToMerge = $DifferenceArray.Where{
                        $DifferenceItem = [ordered]@{} + $_
                        # Search for DiffItem that has the same Property/Value pairs than RefItem
                        $CompareHashParams = @{
                            ReferenceHashtable = [ordered]@{}+$ReferenceItem 
                            DifferenceHashtable = $DifferenceItem
                            Property = $PropertyNames
                        }
                        (!(Compare-Hashtable @CompareHashParams))
                    }
                    Write-Debug "`t`t`t ..Items to merge: $($DiffItemsToMerge.Count)"
                    $DiffItemsToMerge.Foreach{
                        $MergeItemsParams = @{
                            ParentPath = $StartingPath
                            Strategy = $Strategy
                            ReferenceHashtable = $MergedItem
                            DifferenceHashtable = $_
                            ChildStrategies = $ChildStrategies
                        }
                        $MergedItem = Merge-Hashtable @MergeItemsParams
                    }
                    # If a diff Item has been used, save it to find the unused ones
                    $null = $UsedDiffItems.AddRange($DiffItemsToMerge)
                    $null = $MergedArray.Add($MergedItem)
                }
                $UnMergedItems = $DifferenceArray.Foreach{
                    if(!$UsedDiffItems.Contains($_)) {
                        ([ordered]@{} + $_)
                    }
                }
                $null = $MergedArray.AddRange($UnMergedItems)
            }

            # UniqueByProperties
            '^Unique' {
                Write-Debug "`t`t`tSelecting Unique Hashes accross both arrays based on Property tuples"
                # look at each $DiffItems in $DiffArray
                #   if no PropertyNames defined, use all Properties of $DiffItem
                #   else use defined PropertyNames
                #  Search for a RefItem that has the same Property/Value pairs
                #  if Nothing is found
                #    add current DiffItem to RefArray

                if(!$PropertyNames) {
                    Write-Debug "`t`t`t ..No PropertyName defined: Use ReferenceItem Keys"
                    $PropertyNames = $ReferenceItem.Keys
                }

                $MergedArray = [System.Collections.ArrayList]::new()
                $ReferenceArray.Foreach{
                    $CurrentRefItem = $_
                    if(!( $MergedArray.Where{!(Compare-Hashtable -Property $PropertyNames -ReferenceHashtable $CurrentRefItem -DifferenceHashtable $_ )})) {
                        $null = $MergedArray.Add(([ordered]@{} +$_))
                    }
                }

                $DifferenceArray.Foreach{
                    $CurrentDiffItem = $_
                    if(!( $MergedArray.Where{!(Compare-Hashtable -Property $PropertyNames -ReferenceHashtable $CurrentDiffItem -DifferenceHashtable $_ )})) {
                        $null = $MergedArray.Add(([ordered]@{} +$_))
                    }
                }
            }
        }
    }
    
    $MergedArray
}