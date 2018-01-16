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

    Write-verbose "Merge-Datum -StartingPath <$StartingPath>"
    $strategies | ConvertTo-JSon -Depth 10 | Write-Verbose
    $Strategy = Get-MergeStrategyFromPath -Strategies $strategies -PropertyPath $startingPath -Verbose

    Write-Verbose "  Strategy: $($Strategy.Strategy)"
    Write-Debug "---------------------------- $($Strategy | COnvertto-Json)"
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

        'hash' {
            if($ReferenceDatum -isnot [string] -and $ReferenceDatum -is [System.Collections.IEnumerable]) {
                Write-Debug "  HASH Merge: -> array of hashtable. Sending to Merge-DatumArray"
                if($DifferenceDatum -isnot [System.Collections.IEnumerable]) {
                    $DifferenceDatum = @($DifferenceDatum)
                }

                $MergeDatumArrayParams = @{
                    ReferenceArray = $ReferenceDatum
                    DifferenceArray = $DifferenceDatum
                    Strategy = $Strategy
                    ChildStrategies = $Strategies
                    StartingPath = $StartingPath
                }
                Merge-DatumArray @MergeDatumArrayParams
                # it's an array of Hashtable, merge it by position, property, or uniqueness?
            }
            else {
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
        }

        'deep' {
            if($ReferenceDatum -is [hashtable] -or $ReferenceDatum -is [System.Collections.Specialized.OrderedDictionary]) {
                $mergeParams.Add('ChildStrategies',$Strategies)
                Write-Debug "  Merging Hashtables"
                Merge-Hashtable @mergeParams
            }
            elseif($ReferenceDatum -isnot [string] -and $ReferenceDatum -is [System.Collections.IEnumerable]) {
                Write-Debug "  DEEP Merge: -> array of objects. Sending to Merge-DatumArray"
                
                if($DifferenceDatum -isnot [System.Collections.IEnumerable]) {
                    $DifferenceDatum = @($DifferenceDatum)
                }

                $MergeDatumArrayParams = @{
                    ReferenceArray = $ReferenceDatum
                    DifferenceArray = $DifferenceDatum
                    Strategy = $Strategy
                    ChildStrategies = $Strategies
                    StartingPath = $StartingPath
                }
                Merge-DatumArray @MergeDatumArrayParams
            }
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