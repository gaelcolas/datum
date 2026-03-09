function Compare-Hashtable
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ReferenceHashtable,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DifferenceHashtable,

        [Parameter()]
        [string[]]
        $Property = ($ReferenceHashtable.Keys + $DifferenceHashtable.Keys | Select-Object -Unique)
    )

    Write-Debug -Message "Compare-Hashtable -Ref @{$($ReferenceHashtable.keys -join ';')} -Diff @{$($DifferenceHashtable.keys -join ';')} -Property [$($Property -join ', ')]"
    #Write-Debug -Message "REF:`r`n$($ReferenceHashtable | ConvertTo-Json)"
    #Write-Debug -Message "DIFF:`r`n$($DifferenceHashtable | ConvertTo-Json)"

    foreach ($propertyName in $Property)
    {
        Write-Debug -Message "  Testing <$propertyName>'s value"
        if (($inRef = $ReferenceHashtable.Contains($propertyName)) -and
            ($inDiff = $DifferenceHashtable.Contains($propertyName)))
        {
            if ($ReferenceHashtable[$propertyName] -as [hashtable[]] -or $DifferenceHashtable[$propertyName] -as [hashtable[]])
            {
                if ((Compare-Hashtable -ReferenceHashtable $ReferenceHashtable[$propertyName] -DifferenceHashtable $DifferenceHashtable[$propertyName]))
                {
                    Write-Debug -Message "  Skipping $propertyName...."
                    # If compare returns something, they're not the same
                    continue
                }
            }
            else
            {
                Write-Debug -Message "Comparing: $($ReferenceHashtable[$propertyName]) With $($DifferenceHashtable[$propertyName])"
                if ($ReferenceHashtable[$propertyName] -ne $DifferenceHashtable[$propertyName])
                {
                    [PSCustomObject]@{
                        SideIndicator = '<='
                        PropertyName  = $propertyName
                        Value         = $ReferenceHashtable[$propertyName]
                    }

                    [PSCustomObject]@{
                        SideIndicator = '=>'
                        PropertyName  = $propertyName
                        Value         = $DifferenceHashtable[$propertyName]
                    }
                }
            }
        }
        else
        {
            Write-Debug -Message "  Property $propertyName Not in one Side: Ref: [$($ReferenceHashtable.Keys -join ',')] | [$($DifferenceHashtable.Keys -join ',')]"
            if ($inRef)
            {
                Write-Debug -Message "$propertyName found in Reference hashtable"
                [PSCustomObject]@{
                    SideIndicator = '<='
                    PropertyName  = $propertyName
                    Value         = $ReferenceHashtable[$propertyName]
                }
            }
            else
            {
                Write-Debug -Message "$propertyName found in Difference hashtable"
                [PSCustomObject]@{
                    SideIndicator = '=>'
                    PropertyName  = $propertyName
                    Value         = $DifferenceHashtable[$propertyName]
                }
            }
        }
    }

}
