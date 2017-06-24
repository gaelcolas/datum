
function New-DatumFileProvider {
    Param(
        [alias('DataDir')]
        $Path,

        [AllowNull()]
        $DataOptions
    )

    [FileProvider]::new($Path,$DataOptions)
}