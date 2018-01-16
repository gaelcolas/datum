function Merge-DatumArray {
    [CmdletBinding()]
    Param(
        $ReferenceArray,

        $DifferenceArray,

        $Strategy = @{
            strategy = 'hash'
            options = @{
                knockout_prefix    = '--'
                sort_merged_arrays = $false
                merge_basetype_arrays = 'MostSpecific' # = $false, or Unique
                merge_hash_arrays = @{ # $false #or Strategy
                    strategy = 'MostSpecific' #'ByPropertyTuple' or 'Unique'
                    #PropertyNames = 'ObjectProperty1','objectProperty2'
                }
            }
        },

        $ChildStrategies = @{'^.*' = $Strategy},

        $StartingPath
    )
    Write-Debug "`tMerge-DatumArray -StartingPath <$StartingPath>"

    $HashArrayStrategy = $Strategy.options.merge_hash_arrays.Strategy
    Write-Debug "`t`tHash Array Strategy: $HashArrayStrategy"
    $MergeBasetypeArraysStrategy = $Strategy.options.merge_basetype_arrays

    $SortParams = @{}
    if($PropertyNames = [String[]]$Strategy.options.merge_hash_arrays.PropertyNames) {
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
            # MergeHashesByProperties
            '^Merge' {
                Write-Debug "`t`t`tStrategy for Array Items: Merge Hash By tuple`r`n"
                # look at each $RefItems in $RefArray
                #   if no PropertyNames defined, use all Properties of $RefItem
                #   else use defined propertyNames
                #  Search for DiffItem that has the same Property/Value pairs
                #    if found, Merge-Datum (or MergeHashtable?)
                #    if not found, add $DiffItem to $RefArray

                # look at each $RefItems in $RefArray
                $UsedDiffItems = [System.Collections.ArrayList]::new()
                $MergedArray = foreach ($ReferenceItem in $ReferenceArray) {
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
                    $MergedItem
                }
                $UnMergedItems = $DifferenceArray.Foreach{
                    if(!$UsedDiffItems.Contains($_)) {
                        ([ordered]@{} + $_)
                    }
                }
                $MergedArray += $UnMergedItems
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
    elseif(($ReferenceArray.Foreach{$_.getType()} | Select-Object -Unique).ToString() -eq 'System.Management.Automation.PSCustomObject') {
        Write-Debug "`t`tMERGING Arrays of PSObject"
        if(!$HashArrayStrategy -or $HashArrayStrategy -match 'MostSpecific') {
            Write-Debug "`t`tMerge_hash_arrays Disabled"
            $MergedArray = $ReferenceArray
            if($Strategy.sort_merged_arrays) {
                $MergedArray = $MergedArray | Sort-Object @SortParams
            }
            return $MergedArray
        }
        
        switch -Regex ($HashArrayStrategy) {
            # MergeHashesByProperties
            '^Merge' {
                Write-Debug "`t`t`tMerging Array of PSCustomObjects"
                # look at each $RefItems in $RefArray
                #   if no PropertyNames defined, use all Properties of $RefItem
                #   else use defined propertyNames
                #  Search for DiffItem that has the same Property/Value pairs
                #    if found, Merge-Datum (or MergeHashtable?)
                #    if not found, add $DiffItem to $RefArray
                #  
                foreach ($ReferenceItem in $ReferenceArray) {
                    if(!$PropertyNames) {
                        $PropertyNames = $ReferenceArray.PSObject.Properties.Name
                    }
                    throw "Not Implemented yet for PSObjects"
                }
            }

            # UniqueByProperties
            '^Unique' {
                Write-Debug "`t`t`tSelecting Unique PSCustomObjects accross both arrays"
                # look at each $DiffItems in $DiffArray
                #   if no PropertyNames defined, use all Properties of $DiffItem
                #   else use defined PropertyNames
                #  Search for a RefItem that has the same Property/Value pairs
                #  if Nothing is found
                #    add current DiffItem to RefArray
                throw "Not Implemented yet for PSObjects"

            }
        }
    }
    else {
        Write-Debug "`t`tMERGING Arrays of basetype"
        if($MergeBasetypeArraysStrategy -eq 'Unique') {
            # TODO: knockout keys that match ^$knockout_prefix
            $MergedArray = ($ReferenceArray + $DifferenceArray) | Select-Object -Unique
        }
        else {
            Write-Debug "`t`tMerge_basetype_arrays Not relevant, Returning most specific"
            $MergedArray = $ReferenceArray
        }
    }

    if($Strategy.sort_merged_arrays) {
        $MergedArray = $MergedArray | Sort-Object @SortParams
    }
    $MergedArray
}