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

    $jsonDepth = if ($Datum.__Definition.default_json_depth) { $Datum.__Definition.default_json_depth } else { 4 }

    @"
Action: $handler
Node: $($Node|fl *|Out-String)
Params:
$($PSBoundParameters | ConvertTo-Json -Depth $jsonDepth -WarningAction SilentlyContinue)
"@

}
