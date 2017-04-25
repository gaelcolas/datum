
function New-DatumFileProvider {
    Param(
        [alias('DataDir')]
        $Path
    )

    [FileProvider]::new($Path)
}