function ConvertTo-ProtectedDataObject
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.Hashtable]) {
            $InputObject = [PSCustomObject]$InputObject
        }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertTo-ProtectedDataObject $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            #if the InputObject is a PSObject
            # Test if Encrypted Data
            # If ProtectedData -> replace Property by Unprotect-Datum
            # else -> return value
            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertTo-ProtectedDataObject $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}