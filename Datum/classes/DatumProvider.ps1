class DatumProvider {
    hidden [bool]$IsDatumProvider = $true
    hidden [String]$ProviderURI

    [hashtable]ToHashTable()
    {
        $result = ConvertTo-Datum -InputObject $this
        return $result
    }
}