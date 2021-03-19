function New-DatumFileProvider
{
    Param(

        [alias('DataOptions')]
        [AllowNull()]
        $Store,

        [AllowNull()]
        $DatumHierarchyDefinition = @{},

        $Path = $Store.StoreOptions.Path,

        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
    )

    if (!$DatumHierarchyDefinition)
    {
        $DatumHierarchyDefinition = @{}
    }

    [FileProvider]::new($Path, $Store, $DatumHierarchyDefinition, $Encoding)
}
