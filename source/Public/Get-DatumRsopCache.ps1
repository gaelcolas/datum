function Get-DatumRsopCache
{
    [CmdletBinding()]

    param ()

    if ($script:rsopCache.Count)
    {
        $script:rsopCache
    }
    else
    {
        $script:rsopCache = @{}
        Write-Verbose 'The Datum RSOP Cache is empty.'
    }
}
