function New-DatumFileProvider {
    Param(

        [alias('DataOptions')]
        [AllowNull()]
        $Store,

        [AllowNull()]
        $DatumHierarchyDefinition = @{},

        $Path = $Store.StoreOptions.Path,

        [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]
        $Encoding = 'Default'
    )

    if (!$DatumHierarchyDefinition) {
        $DatumHierarchyDefinition = @{}
    }

    [FileProvider]::new($Path, $Store, $DatumHierarchyDefinition, $Encoding)
}
