function Get-MergeStrategyFromPath {
    [CmdletBinding()]
    Param(
        $Strategies,

        $PropertyPath
    )
    
    # Select Relevant strategy
    #   Use exact path match first
    #   or try Regex in order
    if ($StrategyKey = $Strategies.keys.Where{$_ -eq $PropertyPath}) {
        Write-Verbose "Strategy found for exact key $StrategyKey"
    }
    elseif($StrategyKey = $Strategies.keys.where{$_.StartsWith('^') -and $_ -as [regex] -and $PropertyPath -match $_} | Select-Object -First 1) {
        Write-Verbose "Strategy matching regex $StrategyKey"
    }
    else {
        Write-Verbose "No Strategy found"
        return
    }

    if( $Strategies[$StrategyKey] -is [string]) {
        Write-Verbose "Returning from String $($Strategies[$StrategyKey])"
        Get-MergeStrategyFromString $Strategies[$StrategyKey]
    }
    else {
        Write-Debug "Returning $($Strategies[$StrategyKey]|ConvertTo-Json)"
        $Strategies[$StrategyKey]
    }
}