function Test-ProtectedDatumFilter {
    Param(
        [Parameter(
            ValueFromPipeline
        )]
        $InputObject
    )

    $InputObject -is [string] -and $InputObject.Trim() -match "^\[ENC=[\w\W]*\]$"
}