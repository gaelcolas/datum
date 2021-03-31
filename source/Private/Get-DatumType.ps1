function Get-DatumType
{
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $DatumObject
    )

    if ($DatumObject -is [hashtable] -or $DatumObject -is [System.Collections.Specialized.OrderedDictionary])
    {
        'hashtable'
    }
    elseif ($DatumObject -isnot [string] -and $DatumObject -is [System.Collections.IEnumerable])
    {
        if ($DatumObject -as [hashtable[]])
        {
            'hash_array'
        }
        else
        {
            'baseType_array'
        }

    }
    else
    {
        'baseType'
    }

}
