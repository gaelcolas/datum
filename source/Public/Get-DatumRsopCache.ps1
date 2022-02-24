function Get-DatumRsopCache
{
    [CmdletBinding()]

    param ()

    if ($rsopCache.Count)
    {
        $rsopCache
    }
    else
    {
        Write-Verbose 'The Datum RSOP Cache is empty.'
    }
}
