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
        $IncludeSource
    )

    if (-not $script:rsopCache)
    {
        $script:rsopCache = @{}
    }

    if ($Filter.ToString() -ne ([System.Management.Automation.ScriptBlock]::Create( {})).ToString())
    {
        Write-Verbose "Filter: $($Filter.ToString())"
        $AllNodes = [System.Collections.Hashtable[]]$allNodes.Where($Filter)
        Write-Verbose "Node count after applying filter: $($AllNodes.Count)"
    }

    foreach ($Node in $AllNodes)
    {
        if (-not $Node.Name)
        {
            $Node.Name = $Node.NodeName
        }

        $null = $node | ConvertTo-Datum -DatumHandlers $Datum.__Definition.DatumHandlers

        if (-not $script:rsopCache.ContainsKey($Node.Name) -or $IgnoreCache)
        {
            Write-Verbose "Key not found in the cache: '$($Node.Name)'. Creating RSOP..."
            $rsopNode = $Node.Clone()

            $Configurations = Resolve-NodeProperty -PropertyPath $CompositionKey -Node $Node -DatumTree $Datum -DefaultValue @()
            $rsopNode."$CompositionKey" = $Configurations

            $Configurations.ForEach{
                $value = Resolve-NodeProperty -PropertyPath $_ -DefaultValue @{} -Node $Node -DatumTree $Datum
                $rsopNode."$_" = $value
            }

            $lcmConfig = Resolve-NodeProperty -PropertyPath LcmConfig -DefaultValue $null
            if ($lcmConfig)
            {
                $rsopNode.LcmConfig = $lcmConfig
            }

            $clonedRsopNode = Copy-Object -DeepCopyObject $rsopNode
            $clonedRsopNode = ConvertTo-Datum -InputObject $clonedRsopNode -DatumHandlers $Datum.__Definition.DatumHandlers
            $script:rsopCache."$($Node.Name)" = $clonedRsopNode
        }
        else
        {
            Write-Verbose "Key found in the cache: '$($Node.Name)'. Retrieving RSOP from cache."
        }

        if ($IncludeSource)
        {
            Expand-RsopHashtable -InputObject $script:rsopCache."$($Node.Name)" -Depth 0
        }
        else
        {
            $script:rsopCache."$($Node.Name)"
        }
    }
}
