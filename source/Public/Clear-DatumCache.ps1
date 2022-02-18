function Clear-DatumCache
{
    [CmdletBinding()]

    param ()

    $rsopCache.Clear()
}
