function Merge-Datum {
    [CmdletBinding()]
    param (
        $StartingPath,

        $ReferenceDatum,

        $DifferenceDatum,

        $Strategies = @{
            'RootKey1' = @{
                Strategy = 'deep'
                knockoutprefix = '--'
            }

            'RootKey1\subkey11' = @{
                Strategy = 'deep'
                knockoutprefix = '--'
            }

            'RootKey2\subkey23' = @{
                Strategy = 'deep'
                knockoutprefix = '--'
            }

            '^.*' = 'MostSpecific'
        }
    )



    $Strategy = $Strategies[$strategyKey]

    # Merge with strategy
    # ReferenceObjectType
    $ReferenceObjectType = if ($ReferenceDatum -as [hashtable]) {
        'Hash'
    }
    # elseif ($ReferenceDatum )
    # DifferenceObjectType
    #   

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