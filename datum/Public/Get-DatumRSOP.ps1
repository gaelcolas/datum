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