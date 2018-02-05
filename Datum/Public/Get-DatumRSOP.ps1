function Get-DatumRsop {
    [CmdletBinding()]
    Param(
        $Datum,

        [hashtable[]]
        $Element
    )
    # Get-DatumStrategies from a Datum
    $Strategies = [ordered]@{} + $Datum.__Definition.lookup_options
    try {
        $Strategies = $Strategies + [ordered]@{'^.*' = $Datum.__Definition.default_lookup_options }
    }
    catch { 
        "^.* Already defined" | Write-Warning 
    }
    # This is an inaccurate representation of the RSOP
    #  but close enough to be useful in the meantime.
    #  the problem is when starting to merge root with Deep,
    #   the deep strategy propagate recursively until there's an override
    Write-Warning "The RSOP is not 100% accurate in some cases. This will be fixed for v1.0.0"
    $Strategies.add('','deep')

    foreach ($Node in $Element) {
        $MergeDatum = $Node

        $Datum.__Definition.ResolutionPrecedence.Foreach{
            $PrecedencePath = "`$Datum.$($ExecutionContext.InvokeCommand.ExpandString($_)-replace '\\','.')"
            Write-Verbose "Processing $PrecedencePath"
            if(!$PrecedencePath.EndsWith('.')) {
                $NewData = ([scriptblock]::Create($PrecedencePath)).Invoke()[0]
                if($null -eq $MergeDatum) {
                    $MergeDatum = $NewData
                }
                elseif($NewData) {
                    $MergeDatum = Merge-Datum -StartingPath '' -ReferenceDatum $MergeDatum -DifferenceDatum $NewData -Strategies $Strategies
                }
            }
        }

        $MergeDatum
    }
}