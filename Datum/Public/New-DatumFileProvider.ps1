
function New-DatumFileProvider {
    Param(
        
        [alias('DataOptions')]
        [AllowNull()]
        $Store,
        
        [AllowNull()]
        $DatumHierarchyDefinition = @{},

        $Path = $Store.StoreOptions.Path
    )

    if (!$DatumHierarchyDefinition) {
        $DatumHierarchyDefinition = @{}
    }
    
    [FileProvider]::new($Path, $Store,$DatumHierarchyDefinition)
}