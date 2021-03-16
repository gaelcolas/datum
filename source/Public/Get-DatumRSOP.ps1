function Get-DatumRsop {
    [CmdletBinding()]
    Param(
        $Datum,

        [hashtable[]]
        $AllNodes,

        $CompositionKey = 'Configurations',

        [ScriptBlock]
        $Filter = {}
    )

    if($Filter.ToString() -ne ([System.Management.Automation.ScriptBlock]::Create({})).ToString()) {
        Write-Verbose "Filter: $($Filter.ToString())"
        $AllNodes = [System.Collections.Hashtable[]]$allNodes.Where($Filter)
        Write-Verbose "Node count after applying filter: $($AllNodes.Count)"
    }

    foreach ($Node in $AllNodes) {
        $RSOPNode = $Node.clone()

        $Configurations = Lookup $CompositionKey -Node $Node -DatumTree $Datum -DefaultValue @()
        if($RSOPNode.contains($CompositionKey)) {
            $RSOPNode[$CompositionKey] = $Configurations
        }
        else {
            $RSOPNode.add($CompositionKey,$Configurations)
        }

        $Configurations.Foreach{
            if(!$RSOPNode.contains($_)) {
                $RSOPNode.Add($_,(Lookup $_ -DefaultValue @{} -Node $Node -DatumTree $Datum))
            }
            else {
                $RSOPNode[$_] = Lookup $_ -DefaultValue @{} -Node $Node -DatumTree $Datum
            }
        }

        $RSOPNode
    }
}
