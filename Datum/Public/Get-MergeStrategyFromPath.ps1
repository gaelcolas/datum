function Get-MergeStrategyFromPath {
    [CmdletBinding()]
    Param(
        $Strategies,

        $PropertyPath
    )
    
    # Select Relevant strategy
    #   Use exact path match first
    #   or try Regex in order
    if ($StrategyKey = $Strategies.keys.Where{$_ -eq $StartingPath}) {
        Write-Verbose "Strategy found for key $StrategyKey"
    }
    elseif($StrategyKey = $Strategies.keys.where{$_.StartsWith('^') -and $_ -as [regex] -and $startingPath -match $_} | Select-Object -First 1) {
        Write-Verbose "Strategy matching $StrategyKey"
        Write-Output $Strategies[$StrategyKey]
    }
    else {
        Write-Verbose "No Strategy found"
    }
}