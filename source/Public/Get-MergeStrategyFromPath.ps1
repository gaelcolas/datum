function Get-MergeStrategyFromPath
{
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Strategies,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyPath
    )

    Write-Debug -Message "`tGet-MergeStrategyFromPath -PropertyPath <$PropertyPath> -Strategies [$($Strategies.Keys -join ', ')], count $($Strategies.Count)"
    # Select Relevant strategy
    #   Use exact path match first
    #   or try Regex in order
    if ($Strategies.($PropertyPath))
    {
        $strategyKey = $PropertyPath
        Write-Debug -Message "`t  Strategy found for exact key $strategyKey"
    }
    elseif ($Strategies.Keys -and
        ($strategyKey = [string]($Strategies.Keys.Where{ $_.StartsWith('^') -and $_ -as [regex] -and $PropertyPath -match $_ } | Select-Object -First 1))
    )
    {
        Write-Debug -Message "`t  Strategy matching regex $strategyKey"
    }
    else
    {
        Write-Debug -Message "`t  No Strategy found"
        return
    }

    Write-Debug -Message "`t  StrategyKey: $strategyKey"
    if ($Strategies[$strategyKey] -is [string])
    {
        Write-Debug -Message "`t  Returning Strategy $strategyKey from String '$($Strategies[$strategyKey])'"
        Get-MergeStrategyFromString -MergeStrategy $Strategies[$strategyKey]
    }
    else
    {
        Write-Debug -Message "`t  Returning Strategy $strategyKey of type '$($Strategies[$strategyKey].Strategy)'"
        $Strategies[$strategyKey]
    }
}
