function Invoke-TestHandlerAction
{
    Param(
        $Password,

        $test,

        $Datum
    )
    @"
    Action: $handler
    Node: $($Node|fl *|Out-String)
    Params:
$($PSBoundParameters | ConvertTo-Json)
"@
}
