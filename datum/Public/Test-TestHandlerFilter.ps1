function Test-TestHandlerFilter {
    Param(
        [Parameter(
            ValueFromPipeline
        )]
        $inputObject
    )

    $InputObject -is [string] -and $InputObject -match "^\[TEST=[\w\W]*\]$"
}
