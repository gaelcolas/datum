function ConvertTo-Datum
{
    param (
        [Parameter(ValueFromPipeline = $true)]
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

        if ($null -eq $InputObject)
        {
            return $null
        }

        if ($InputObject -is [System.Collections.IDictionary])
        {
            if (-not $file -and $InputObject.__File)
            {
                $file = $InputObject.__File
            }

            $hashKeys = [string[]]$InputObject.Keys
            foreach ($key in $hashKeys)
            {
                $InputObject[$key] = ConvertTo-Datum -InputObject $InputObject[$key] -DatumHandlers $DatumHandlers
            }
            # Making the Ordered Dict Case Insensitive
            ([ordered]@{} + $InputObject) | Add-Member -Name __File -MemberType NoteProperty -Value "$file" -PassThru -Force
        }
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject)
                {
                    if (-not $file -and $object.__File)
                    {
                        $file = $object.__File
                    }
                    ConvertTo-Datum -InputObject $object -DatumHandlers $DatumHandlers
                }
            )

            , $collection
        }
        elseif (($InputObject -is [DatumProvider]) -and $InputObject -isnot [pscredential])
        {
            if (-not $file -and $InputObject.__File)
            {
                $file = $InputObject.__File
            }

            $hash = [ordered]@{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertTo-Datum -InputObject $property.Value -DatumHandlers $DatumHandlers | Add-Member -Name __File -MemberType NoteProperty -Value $File.FullName -PassThru -Force
            }

            $hash
        }
        # if there's a matching filter, process associated command and return result
        elseif ($DatumHandlers.Count -and (Invoke-DatumHandler -InputObject $InputObject -DatumHandlers $DatumHandlers -Result ([ref]$result)))
        {
            if (-not $file -and $InputObject.__File)
            {
                $file = $InputObject.__File
            }

            if ($null -ne $result)
            {
                if (-not $result.__File -and $InputObject.__File)
                {
                    $result | Add-Member -Name __File -Value "$($InputObject.__File)" -MemberType NoteProperty -PassThru -Force
                }
                elseif (-not $result.__File -and $file)
                {
                    $result | Add-Member -Name __File -Value "$($file)" -MemberType NoteProperty -PassThru -Force
                }
                else
                {
                    $result
                }
            }
            else
            {
                Write-Verbose "Datum handlers for '$InputObject' returned '$null'"
                $null
            }
        }
        else
        {
            if (-not $file -and $InputObject.__File)
            {
                $file = $InputObject.__File
            }

            if ($file -and -not $InputObject.__File)
            {
                $InputObject | Add-Member -Name __File -Value "$file" -MemberType NoteProperty -PassThru -Force
            }
            else
            {
                $InputObject
            }
        }
    }
}
