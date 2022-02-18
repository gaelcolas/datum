function Clear-DatumCache
{
    [CmdletBinding()]

    param ()

    if ($rsopCache)
    {
        $rsopCache.Clear()
        Write-Debug -Message 'RSOP Cache cleared'
    }
}
