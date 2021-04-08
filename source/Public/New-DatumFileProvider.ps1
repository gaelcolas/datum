function New-DatumFileProvider
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [Alias('DataOptions')]
        [AllowNull()]
        [object]
        $Store,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHierarchyDefinition = @{},

        [Parameter()]
        [string]
        $Path = $Store.StoreOptions.Path,

        [Parameter()]
        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
    )

    if (-not $DatumHierarchyDefinition)
    {
        $DatumHierarchyDefinition = @{}
    }

    [FileProvider]::new($Path, $Store, $DatumHierarchyDefinition, $Encoding)
}
