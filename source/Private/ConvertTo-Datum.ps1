function ConvertTo-Datum
{
    param (
        [Parameter(ValueFromPipeline)]
        [object]
        $InputObject,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHandlers = @{}
    )

    process
    {
        $result = $null
        if (-not $File -and $InputObject.__File)
        {
            $File = $InputObject.__File
        }

        if ($null -eq $InputObject)
        {
            return $null
        }

        if ($InputObject -is [System.Collections.IDictionary])
        {
            $hashKeys = [string[]]$InputObject.Keys
            foreach ($key in $hashKeys)
            {
                $InputObject[$key] = ConvertTo-Datum -InputObject $InputObject[$key] -DatumHandlers $DatumHandlers
            }
            # Making the Ordered Dict Case Insensitive
            ([ordered]@{} + $InputObject)
        }
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject)
                {
                    ConvertTo-Datum -InputObject $object -DatumHandlers $DatumHandlers
                }
            )

            , $collection
        }
        elseif (($InputObject -is [DatumProvider]) -and $InputObject -isnot [pscredential])
        {
            $hash = [ordered]@{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertTo-Datum -InputObject $property.Value -DatumHandlers $DatumHandlers
            }

            $hash
        }
        # if there's a matching filter, process associated command and return result
        elseif ($DatumHandlers.Count -and (Invoke-DatumHandler -InputObject $InputObject -DatumHandlers $DatumHandlers -Result ([ref]$result)))
        {
            if (-not $result.__File -and $InputObject.__File)
            {
                $result | Add-Member -Name __File -Value "$($InputObject.__File)" -MemberType NoteProperty -PassThru
            }
            elseif (-not $result.__File -and $File)
            {
                $result | Add-Member -Name __File -Value "$($File)" -MemberType NoteProperty -PassThru
            }
            else
            {
                $result
            }
        }
        else
        {
            if ($File -and -not $InputObject.__File)
            {
                $InputObject | Add-Member -Name __File -Value "$File" -MemberType NoteProperty -PassThru
            }
            else
            {
                $InputObject
            }
        }
    }
}
