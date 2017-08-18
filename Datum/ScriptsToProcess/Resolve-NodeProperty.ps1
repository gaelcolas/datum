function Resolve-NodeProperty {
    [CmdletBinding()]
    Param(
        $Node,
        $PropertyPath,
        $DefaultValue,
        $SearchPaths = $ExecutionContext.InvokeCommand.InvokeScript('$yml.ResolutionPrecedence'),
        $DatumStructure = $ExecutionContext.InvokeCommand.InvokeScript('$ConfigurationData.Datum')
    )
    
    if($result = Resolve-Datum -PropertyPath $PropertyPath -Node $Node -SearchPaths $SearchPaths -DatumStructure $DatumStructure) {
        $result
    }
    elseif($Default) {
        $Default
    }
    elseif($PSBoundParameters.ContainsKey('Default') -and $null -eq $Default) {
        $null
    }
    else {
        throw "The lookup returned a Null value, but Null is not specified as Default. This is not allowed."
    }

}
Set-Alias -Name Lookup -Value Resolve-NodeProperty #-Scope Global