function Clear-DatumRsopCache
{
    [CmdletBinding()]

    param ()

    if ($script:rsopCache.Count)
    {
        $script:rsopCache.Clear()
        Write-Verbose -Message 'Datum RSOP Cache cleared'
    }
}
