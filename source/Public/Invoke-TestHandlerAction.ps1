function Invoke-TestHandlerAction
{
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Password,

        [Parameter()]
        [object]
        $Test,

        [Parameter()]
        [object]
        $Datum
    )

    @"
Action: $handler
Node: $($Node|fl *|Out-String)
Params:
$($PSBoundParameters | ConvertTo-Json)
"@

}
