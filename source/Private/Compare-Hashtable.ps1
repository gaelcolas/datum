function Compare-Hashtable {
    [CmdletBinding()]
    Param(
        
        $ReferenceHashtable,

        $DifferenceHashtable,

        [string[]]
        $Property = ($ReferenceHashtable.Keys + $DifferenceHashtable.Keys | Select-Object -Unique)
    )

    Write-Debug "Compare-Hashtable -Ref @{$($ReferenceHashtable.keys -join ';')} -Diff @{$($DifferenceHashtable.keys -join ';')} -Property [$($Property -join ', ')]"
    #Write-Debug "REF:`r`n$($ReferenceHashtable|ConvertTo-JSON)"
    #Write-Debug "DIFF:`r`n$($DifferenceHashtable|ConvertTo-JSON)"

    foreach ($PropertyName in $Property) {
        Write-debug "  Testing <$PropertyName>'s value"
        if( ($inRef = $ReferenceHashtable.Contains($PropertyName)) -and
            ($inDiff = $DifferenceHashtable.Contains($PropertyName))
          ) 
        {
            if($ReferenceHashtable[$PropertyName] -as [hashtable[]] -or $DifferenceHashtable[$PropertyName] -as [hashtable[]] ) {
                if( (Compare-Hashtable -ReferenceHashtable $ReferenceHashtable[$PropertyName] -DifferenceHashtable $DifferenceHashtable[$PropertyName]) ) {
                    Write-Debug "  Skipping $PropertyName...."
                    # If Compae returns something, they're not the same
                    Continue
                }
            }
            else {
                Write-Debug "Comparing: $($ReferenceHashtable[$PropertyName]) With $($DifferenceHashtable[$PropertyName])"
                if($ReferenceHashtable[$PropertyName] -ne $DifferenceHashtable[$PropertyName]) {
                    [PSCustomObject]@{
                        SideIndicator = '<='
                        PropertyName = $PropertyName
                        Value = $ReferenceHashtable[$PropertyName]
                    }

                    [PSCustomObject]@{
                        SideIndicator = '=>'
                        PropertyName = $PropertyName
                        Value = $DifferenceHashtable[$PropertyName]
                    }
                }
            }
        }
        else {
            Write-Debug "  Property $PropertyName Not in one Side: Ref: [$($ReferenceHashtable.Keys -join ',')] | [$($DifferenceHashtable.Keys -join ',')]"
            if($inRef) {
                Write-Debug "$PropertyName found in Reference hashtable"
                [PSCustomObject]@{
                    SideIndicator = '<='
                    PropertyName = $PropertyName
                    Value = $ReferenceHashtable[$PropertyName]
                }
            }
            else {
                Write-Debug "$PropertyName found in Difference hashtable"
                [PSCustomObject]@{
                    SideIndicator = '=>'
                    PropertyName = $PropertyName
                    Value = $DifferenceHashtable[$PropertyName]
                }
            }
        }
    }
    
}