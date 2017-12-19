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
    $PropertySeparator = '.' #[io.path]::DirectorySeparatorChar
    $index = -1
    Write-Debug "`t`t`t"
    
    foreach ($StackItem in $PathStack) {
        $index++
        $RelativePath = $PathStack[0..$index]
        Write-Debug "`t`t`tCurrent Path: `$Datum$PropertySeparator$($RelativePath -join '\')"
        $RemainingStack = $PathStack[$index..($PathStack.Count-1)]
        Write-Debug "`t`t`t`tbranch of path Left to walk: PropertySeparator$($RemainingStack[1..$RemainingStack.Length] -join $PropertySeparator)"
        if ( $StackItem -match '\{\d+\}') {
            Write-Debug -Message "`t`t`t`t`tReplacing expression $StackItem"
            $StackItem = [scriptblock]::Create( ($StackItem -f ([string[]]$PathVariables)) ).Invoke()
            Write-Debug -Message ($StackItem | Format-List * | Out-String)
            $PathItem = $stackItem
        }
        else {
            $PathItem = $CurrentNode.($ExecutionContext.InvokeCommand.ExpandString($StackItem))
        }

        # if $PathItem is $null, it won't have subkeys, stop execution for this Prefix
        if($null -eq $PathItem) { 
            Write-Verbose -Message " NULL FOUND at `$Datum.$($ExecutionContext.InvokeCommand.ExpandString(($RelativePath -join $PropertySeparator) -f [string[]]$PathVariables))`t`t <`$Datum$PropertySeparator$(($RelativePath -join $PropertySeparator) -f [string[]]$PathVariables)>"
            if($RemainingStack.Count -gt 1) {
                Write-Verbose -Message "`t`t----> before:  $propertySeparator$($ExecutionContext.InvokeCommand.ExpandString(($RemainingStack[1..($RemainingStack.Count-1)] -join $PropertySeparator)))`t`t <$(($RemainingStack[1..($RemainingStack.Count-1)] -join $PropertySeparator) -f [string[]]$PathVariables)>"
            } 
            Return $null
        }
        else {
            $CurrentNode = $PathItem
        }
        

        if ($RemainingStack.Count -eq 1) {
            Write-Verbose -Message " VALUE found at `$Datum$PropertySeparator$($ExecutionContext.InvokeCommand.ExpandString(($RelativePath -join $PropertySeparator) -f [string[]]$PathVariables))"
            Write-Output $CurrentNode
        }
        
    }
}