function Get-DatumRsop {
    [CmdletBinding()]
    Param(
        $Datum,

        [hashtable[]]
        $AllNodes,

        $CompositionKey = 'Configurations'

    )

    foreach ($Node in $AllNodes) {
        $RSOPNode = $Node.clone()

        $Configurations = Lookup Configurations -Node $Node -DatumTree $Datum -DefaultValue @()
        if($RSOPNode.contains($CompositionKey)) {
            $RSOPNode[$CompositionKey] = $Configurations
        }
        else {
            $RSOPNode.add($CompositionKey,$Configurations)
        }
        
        $Configurations.Foreach{
            if(!$RSOPNode.contains($_)) {
                $RSOPNode.Add($_,(Lookup $_ -DefaultValue @{}))
            }
            else {
                $RSOPNode[$_] = Lookup $_ -DefaultValue @{}
            }
        }

        $RSOPNode
    }
}