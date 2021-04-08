function Test-TestHandlerFilter
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject
    )

    $InputObject -is [string] -and $InputObject -match '^\[TEST=[\w\W]*\]$'
}
