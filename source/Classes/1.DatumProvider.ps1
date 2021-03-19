class DatumProvider
{
    hidden [bool]$IsDatumProvider = $true

    [hashtable]ToHashTable()
    {
        $result = ConvertTo-Datum -InputObject $this
        return $result
    }

    [System.Collections.Specialized.OrderedDictionary]ToOrderedHashTable()
    {
        $result = ConvertTo-Datum -InputObject $this
        return $result
    }
}
