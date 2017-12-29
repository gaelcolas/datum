function ConvertTo-Hashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.Hashtable] -or
           ($InputObject -is [System.Collections.Specialized.OrderedDictionary]) -or
           ($InputObject -is [System.Management.Automation.PSCredential])) {
            return $InputObject
        }
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertTo-Hashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject] -or $InputObject -is [SecureDatum])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertTo-Hashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}
