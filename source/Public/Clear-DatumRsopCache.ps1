function Clear-DatumRsopCache
{
    [CmdletBinding()]

    param ()

    if ($rsopCache.Count)
    {
        $rsopCache.Clear()
        Write-Verbose -Message 'Datum RSOP Cache cleared'
    }
}
