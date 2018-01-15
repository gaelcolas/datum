function Compare-Hashtable {
    Param(
        [hashtable]
        $ReferenceHashtable,

        [hashtable]
        $DifferenceHashtable,

        [string[]]
        $Property = ($ReferenceHashtable.Keys + $DifferenceHashtable.Keys | Select-Object -Unique)
    )

    foreach ($Property in $PropertyName) {

        if( ($inRef = $ReferenceHashtable.Contains($Property)) -and
            ($inDiff = $DifferenceHashtable.Contains($Property))
          ) 
        {
            if($ReferenceHashtable[$Property] -as [hashtable[]] -or $DifferenceHashtable[$Property] -as [hashtable[]] ) {
                if( (Compare-Hashtable -ReferenceHashtable $ReferenceHashtable[$Property] -DifferenceHashtable $DifferenceHashtable[$Property]) ) {
                    # If Compae returns something, they're not the same
                    Continue
                }
            }
            else {
                if($ReferenceHashtable[$Property] -ne $DifferenceHashtable[$Property]) {
                    [PSCustomObject]@{
                        SideIndicator = '<='
                        PropertyName = $Property
                        Value = $ReferenceHashtable[$Property]
                    }

                    [PSCustomObject]@{
                        SideIndicator = '=>'
                        PropertyName = $Property
                        Value = $DifferenceHashtable[$Property]
                    }
                }
            }
        }
        else {
            if($inRef) {
                [PSCustomObject]@{
                    SideIndicator = '<='
                    PropertyName = $Property
                    Value = $ReferenceHashtable[$Property]
                }
            }
            else {
                [PSCustomObject]@{
                    SideIndicator = '=>'
                    PropertyName = $Property
                    Value = $DifferenceHashtable[$Property]
                }
            }
        }
    }
    
}