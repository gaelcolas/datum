function Get-DatumRsop
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Datum,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $AllNodes,

        [Parameter()]
        [string]
        $CompositionKey = 'Configurations',

        [Parameter()]
        [scriptblock]
        $Filter = {},

        [Parameter()]
        [switch]
        $IgnoreCache,

        [Parameter()]
        [switch]
        $IncludeSource,

        [Parameter()]
        [switch]
        $RemoveSource
    )

    if (-not $script:rsopCache)
    {
        $script:rsopCache = @{}
    }

    if ($Filter.ToString() -ne ([System.Management.Automation.ScriptBlock]::Create( {})).ToString())
    {
        Write-Verbose "Filter: $($Filter.ToString())"
        $AllNodes = [System.Collections.Hashtable[]]$AllNodes.Where($Filter)
        Write-Verbose "Node count after applying filter: $($AllNodes.Count)"
    }

    foreach ($node in $AllNodes)
    {
        if (-not $node.Name)
        {
            $node.Name = $node.NodeName
        }

        $null = $node | ConvertTo-Datum -DatumHandlers $Datum.__Definition.DatumHandlers

        if (-not $script:rsopCache.ContainsKey($node.Name) -or $IgnoreCache)
        {
            Write-Verbose "Key not found in the cache: '$($node.Name)'. Creating RSOP..."
            $rsopNode = $node.Clone()

            $configurations = Resolve-NodeProperty -PropertyPath $CompositionKey -Node $node -DatumTree $Datum -DefaultValue @()
            $rsopNode."$CompositionKey" = $configurations

            $configurations.ForEach{
                $value = Resolve-NodeProperty -PropertyPath $_ -DefaultValue @{} -Node $node -DatumTree $Datum
                $rsopNode."$_" = $value
            }

            $lcmConfig = Resolve-NodeProperty -PropertyPath LcmConfig -DefaultValue $null
            if ($lcmConfig)
            {
                $rsopNode.LcmConfig = $lcmConfig
            }

            $clonedRsopNode = Copy-Object -DeepCopyObject $rsopNode
            $clonedRsopNode = ConvertTo-Datum -InputObject $clonedRsopNode -DatumHandlers $Datum.__Definition.DatumHandlers
            $script:rsopCache."$($node.Name)" = $clonedRsopNode
        }
        else
        {
            Write-Verbose "Key found in the cache: '$($node.Name)'. Retrieving RSOP from cache."
        }

        if ($IncludeSource)
        {
            Expand-RsopHashtable -InputObject $script:rsopCache."$($node.Name)" -Depth 0
        }
        elseif ($RemoveSource)
        {
            Expand-RsopHashtable -InputObject $script:rsopCache."$($node.Name)" -Depth 0 -AddSourceInformation
        }
        else
        {
            $script:rsopCache."$($node.Name)"
        }
    }
}
