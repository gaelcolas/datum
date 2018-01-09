function Invoke-TestHandlerAction {
    Param(
        $Password,

        $test,

        $Datum
    )
@"
    Action: $handler
    Node: $($Node|FL *|Out-String)
    Params: 
$($PSBoundParameters | Convertto-Json)
"@
}