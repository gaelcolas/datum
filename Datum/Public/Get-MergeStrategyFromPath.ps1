function Get-MergeStrategyFromPath {
    [CmdletBinding()]
    Param(
        $Strategies,

        $PropertyPath
    )
    Write-debug "`tGet-MergeStrategyFromPath -PropertyPath <$PropertyPath> -Strategies $Strategies, count $($Strategies.count)"
    # Select Relevant strategy
    #   Use exact path match first
    #   or try Regex in order
    if ($Strategies.($PropertyPath)) {
        $StrategyKey = $PropertyPath
        Write-debug "`t  Strategy found for exact key $StrategyKey"
    }
    elseif($Strategies.keys -and
            ($StrategyKey = [string]($Strategies.keys.where{$_.StartsWith('^') -and $_ -as [regex] -and $PropertyPath -match $_} | Select-Object -First 1))
          ) 
    {
        Write-debug "`t  Strategy matching regex $StrategyKey"
    }
    else {
        Write-debug "`t  No Strategy found"
        return
    }

    Write-Debug "`t  StrategyKey: $StrategyKey"
    if( $Strategies[$StrategyKey] -is [string]) {
        Write-debug "`t  Returning Strategy $StrategyKey from String '$($Strategies[$StrategyKey])'"
        Get-MergeStrategyFromString $Strategies[$StrategyKey]
    }
    else {
        Write-Debug "`t  Returning Strategy $StrategyKey of type '$($Strategies[$StrategyKey].Strategy)'"
        $Strategies[$StrategyKey]
    }
}