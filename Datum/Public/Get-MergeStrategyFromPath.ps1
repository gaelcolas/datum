function Get-MergeStrategyFromPath {
    [CmdletBinding()]
    Param(
        $Strategies,

        $PropertyPath
    )
    Write-debug ">>> MergeStrategyFromPath $PropertyPath"
    # Select Relevant strategy
    #   Use exact path match first
    #   or try Regex in order
    if ($Strategies[$PropertyPath]) {
        $StrategyKey = $PropertyPath
        Write-debug "`tStrategy found for exact key $StrategyKey"
    }
    elseif($StrategyKey = [string]($Strategies.keys.where{$_.StartsWith('^') -and $_ -as [regex] -and $PropertyPath -match $_} | Select-Object -First 1)) {
        Write-debug "`tStrategy matching regex $StrategyKey"
    }
    else {
        Write-debug "`tNo Strategy found"
        return
    }
    Write-Debug "`tStrategyKey: $StrategyKey. $($Strategies[$StrategyKey].getType())"
    if( $Strategies[$StrategyKey] -is [string]) {
        Write-debug "`tReturning from String $($Strategies[$StrategyKey])"
        Get-MergeStrategyFromString $Strategies[$StrategyKey]
    }
    else {
        Write-Debug "`tReturning $($Strategies[$StrategyKey]|ConvertTo-Json)"
        $Strategies[$StrategyKey]
    }
}