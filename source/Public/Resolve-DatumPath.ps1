function Resolve-DatumPath
{
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter()]
        [Alias('Variable')]
        $Node,

        [Parameter()]
        [Alias('DatumStructure')]
        [object]
        $DatumTree,

        [Parameter()]
        [string[]]
        $PathStack,

        [Parameter()]
        [System.Collections.ArrayList]
        $PathVariables
    )

    $currentNode = $DatumTree
    $propertySeparator = '.' #[System.IO.Path]::DirectorySeparatorChar
    $index = -1
    Write-Debug -Message "`t`t`t"

    foreach ($stackItem in $PathStack)
    {
        $index++
        $relativePath = $PathStack[0..$index]
        Write-Debug -Message "`t`t`tCurrent Path: `$Datum$propertySeparator$($relativePath -join $propertySeparator)"
        $remainingStack = $PathStack[$index..($PathStack.Count - 1)]
        Write-Debug -Message "`t`t`t`tbranch of path Left to walk: $propertySeparator$($remainingStack[1..$remainingStack.Length] -join $propertySeparator)"

        if ($stackItem -match '\{\d+\}')
        {
            Write-Debug -Message "`t`t`t`t`tReplacing expression $stackItem"
            $stackItem = [scriptblock]::Create(($stackItem -f ([string[]]$PathVariables)) ).Invoke()
            Write-Debug -Message ($stackItem | Format-List * | Out-String)
            $pathItem = $stackItem
        }
        else
        {
            $pathItem = $currentNode.($ExecutionContext.InvokeCommand.ExpandString($stackItem))
        }

        # if $pathItem is $null, it won't have subkeys, stop execution for this Prefix
        if ($null -eq $pathItem)
        {
            Write-Verbose -Message " NULL FOUND at `$Datum.$($ExecutionContext.InvokeCommand.ExpandString(($relativePath -join $propertySeparator) -f [string[]]$PathVariables))`t`t <`$Datum$propertySeparator$(($relativePath -join $propertySeparator) -f [string[]]$PathVariables)>"
            if ($remainingStack.Count -gt 1)
            {
                Write-Verbose -Message "`t`t----> before:  $propertySeparator$($ExecutionContext.InvokeCommand.ExpandString(($remainingStack[1..($remainingStack.Count-1)] -join $propertySeparator)))`t`t <$(($remainingStack[1..($remainingStack.Count-1)] -join $propertySeparator) -f [string[]]$PathVariables)>"
            }
            return $null
        }
        else
        {
            $currentNode = $pathItem
        }


        if ($remainingStack.Count -eq 1)
        {
            Write-Verbose -Message " VALUE found at `$Datum$propertySeparator$($ExecutionContext.InvokeCommand.ExpandString(($relativePath -join $propertySeparator) -f [string[]]$PathVariables))"
            , $currentNode
        }

    }
}
