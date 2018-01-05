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

    Write-Verbose "`r`nPATH: $StartingPath. Strategies : $($strategies|Convertto-Json)"
    Write-Debug "REF $($ReferenceDatum|Convertto-JSon)"
    $Strategy = Get-MergeStrategyFromPath -Strategies $strategies -PropertyPath $startingPath -Verbose

    Write-Verbose "Strategy: $($Strategy | ConvertTo-Json)"
    # Merge with strategy
    $mergeParams = @{
        ReferenceHashtable  = $ReferenceDatum
        DifferenceHashtable = $DifferenceDatum
        Strategy = $Strategy
        ParentPath = $StartingPath
    }

    switch ($Strategy.Strategy) {
        'MostSpecific' { return $ReferenceDatum}
        'AllValues'    { return $DifferenceDatum }
        
        'Unique'       {
            if($ReferenceDatum -as [hashtable]) {
                $ReferenceDatum = @($ReferenceDatum)
            }

            if($DifferenceDatum -as [hashtable]) {
                $DifferenceDatum = @($DifferenceDatum)
            }

            if($ReferenceDatum -as [hashtable[]]) {
                # it's an array of Hashtable objects, merge it by uniqueness
                #   compare those with same set of Keys, then compare values? or compare object for sum of keys
            }
            elseif ($ReferenceDatum -is [System.Collections.IEnumerable] -and $ReferenceDatum -isnot [string]) {
                # it's another type of collection
                # cast refdatum to object[], add $diffDatum values, select unique, return 
                @($ReferenceDatum + $DifferenceDatum) | Select-Object -Unique
            }
        }

        'hash'         {
            # ignore non-hashtable elements (replace with empty hash)
            if(!($ReferenceDatum -as [hashtable])) {
                $mergeParams['ReferenceHashtable'] = @{}
            }

            if(!($DifferenceDatum -as [hashtable])) {
                $mergeParams['DifferenceHashtable'] = @{}
            }

            # merge top layer keys, ignore subkeys
            Merge-Hashtable @mergeParams
        }

        'deep' {
            if($ReferenceDatum -as [hashtable[]]) {
                # it's an array of Hashtable, merge it by position, property, or uniqueness?
            }
            Write-Debug "adding Child Startegies: $($Strategies|ConvertTo-Json)"
            $mergeParams.Add('ChildStrategies',$Strategies)
            Merge-Hashtable @mergeParams
        }

    }

    # Strategy is MostSpecific --> No Merge
    # strategy is All Values --> No Merge, return all
    
    # Strategy is Unique --> cast to refdatum [object[]] + diffDatum | select Unique
    # Strategy is Hash --> Merge Keys.
    # Strategy is Deep 
    #     --> is Array or [object[]]Value
    #         --> Merge Hash[]?
    #           ---> No, only keep refDatum
    #           ---> Uniques: cast to refdatum [object[]] + diffDatum | select Unique
    #           ---> ByKey:   Merge ArrayItem.Where{$_.key -match refArrayItem.Key}
    #               --> SubMode? Deep or hash
    #           ---> ByPosition: Merge Ref[itemIndex] with Diff[itemIndex]
    #               --> SubMode? Deep or hash
    #     --> is Hash/Ordered

}