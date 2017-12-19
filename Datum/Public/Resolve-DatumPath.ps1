function Resolve-DatumPath {
    [CmdletBinding()]
    param(
        $Node,

        $DatumStructure,

        [string[]]
        $PathStack,

        [System.Collections.ArrayList]
        $PathVariables
    )
    
    $currentNode = $DatumStructure
    
    foreach ($StackItem in $PathStack) {
        $RelativePath = $PathStack[0..$PathStack.IndexOf($StackItem)]
        Write-Verbose "`tCurrent relative Path: $($RelativePath -join '\')"
        $LeftOfStack = $PathStack[$PathStack.IndexOf($StackItem)..($PathStack.Count-1)]
        Write-Verbose "`t`tLeft Path to search: $($LeftOfStack -join '\')"
        if ( $StackItem -match '\{\d+\}') {
            Write-Debug -Message "`t`t`tReplacing expression $StackItem"
            $StackItem = [scriptblock]::Create( ($StackItem -f ([string[]]$PathVariables)) ).Invoke()
            Write-Debug -Message ($StackItem | Format-List * | Out-String)
            $PathItem = $stackItem
        }
        else {
            $PathItem = $CurrentNode.($ExecutionContext.InvokeCommand.ExpandString($StackItem))
        }

        switch ($PathItem) {
            $null {
                Write-Verbose -Message "`tNULL FOUND AT PATH: $(($RelativePath -join '\') -f [string[]]$PathVariables) before reaching $($LeftOfStack -join '\')"
                Return $null
            }
            {$_.GetType() -eq [hashtable]} { $CurrentNode = $PathItem; Break }
            default                        { $CurrentNode = $PathItem; break }
        }

        if ($LeftOfStack.Count -eq 1) {
            Write-Output $CurrentNode
        }
        
    }
}