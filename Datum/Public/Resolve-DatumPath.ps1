function Resolve-DatumPath {
    [CmdletBinding()]
    param(
        $Node,

        $DatabagNode,

        [string[]]
        $PathStack,

        [System.Collections.ArrayList]
        $PathVariables,

        [ref]
        $Value
    )
    
    $currentNode = $DatabagNode
    
    foreach ($StackItem in $PathStack) {
        $RelativePath = $PathStack[0..$PathStack.IndexOf($StackItem)]
        Write-Verbose "Current relative Path: $($RelativePath -join '\')"
        $LeftOfStack = $PathStack[$PathStack.IndexOf($StackItem)..($PathStack.Count-1)]
        Write-Verbose "Left Path to search: $($LeftOfStack -join '\')"
        if ( $StackItem -match '\{\d+\}') {
            Write-Verbose -Message "Replacing expression $StackItem"
            $StackItem = [scriptblock]::Create( ($StackItem -f ([string[]]$PathVariables)) ).Invoke()
            Write-Verbose -Message ($StackItem | FL * | Out-String)
            $PathItem = $stackItem
        }
        else {
            $PathItem = $CurrentNode.($StackItem)
        }

        switch ($PathItem) {
            $null {
                Write-Verbose -Message "NULL FOUND AT PATH: $(($RelativePath -join '\') -f [string[]]$PathVariables) before reaching $($LeftOfStack -join '\')"
                Return $null
            }
            {$_.GetType() -eq [hashtable]} { $CurrentNode = $PathItem; Break}
            #{$_.GetType() -eq [string[]]}  { $_.Foreach{Resolve-ObjectPath @PSBoundParameters -DatabagNode $currentNode.($_) -PathStack $LeftOfStack}; break}
            default                        { $CurrentNode = $PathItem; break }
        }

        if ($LeftOfStack.Count -eq 1) {
            Write-Output $CurrentNode
        }
        
    }
}