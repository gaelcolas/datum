function Get-DatumRsop
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Datum,

        [Parameter()]
        [hashtable[]]
        $AllNodes,

        [Parameter()]
        [string]
        $CompositionKey = 'Configurations',

        [Parameter()]
        [scriptblock]
        $Filter = {}
    )

    if ($Filter.ToString() -ne ([System.Management.Automation.ScriptBlock]::Create( {})).ToString())
    {
        Write-Verbose -Message "Filter: $($Filter.ToString())"
        $AllNodes = [System.Collections.Hashtable[]]$allNodes.Where($Filter)
        Write-Verbose -Message "Node count after applying filter: $($AllNodes.Count)"
    }

    foreach ($node in $AllNodes)
    {
        $rsopNode = $node.clone()

        $configurations = Lookup $CompositionKey -Node $node -DatumTree $Datum -DefaultValue @()
        if ($rsopNode.contains($CompositionKey))
        {
            $rsopNode[$CompositionKey] = $configurations
        }
        else
        {
            $rsopNode.Add($CompositionKey, $configurations)
        }

        $configurations.Foreach{
            if (-not $rsopNode.Contains($_))
            {
                $rsopNode.Add($_, (Lookup -PropertyPath $_ -DefaultValue @{} -Node $node -DatumTree $Datum))
            }
            else
            {
                $rsopNode[$_] = Lookup -PropertyPath $_ -DefaultValue @{} -Node $node -DatumTree $Datum
            }
        }

        $rsopNode
    }
}
