function Global:Resolve-NodeProperty {
    [CmdletBinding()]
    Param(

        $Node,

        $PropertyPath,

        [AllowNull()]
        $DefaultValue,

        $DatumStructure = $ExecutionContext.InvokeCommand.InvokeScript('$ConfigurationData.Datum'),
        
        $SearchPaths = $DatumStructure.__Definition.ResolutionPrecedence
    )

    # Null result should return an exception, unless defined as Default value
    $NullAllowed = $false

    if($result = Resolve-Datum -PropertyPath $PropertyPath -Node $Node -SearchPaths $SearchPaths -DatumStructure $DatumStructure) {
        Write-Verbose "`tResult found for $PropertyPath"
    }
    elseif($DefaultValue) {
        $result = $DefaultValue
        Write-Debug "`t`tDefault Found"
    }
    elseif($PSBoundParameters.ContainsKey('DefaultValue') -and $null -eq $DefaultValue) {
        $result = $null
        $NullAllowed = $true
        Write-Debug "`t`tDefault NULL found"
    }
    else { 
        #This is when the Lookup is initiated from a Composite Resource, for itself
        
        if(-not ($here = $MyInvocation.PSScriptRoot)) {
            $here = $Pwd.Path
        }
        Write-Debug "`t`tAttempting to load datum from $($here)."
        
        $ResourceConfigDataPath = Join-Path $here 'ConfigData' -Resolve -ErrorAction SilentlyContinue

        if($ResourceConfigDataPath) {
            $DatumDefinitionFile = Join-Path $ResourceConfigDataPath 'Datum.*' -Resolve -ErrorAction SilentlyContinue
            if($DatumDefinitionFile) {
                Write-Debug "Resource Datum File Path: $DatumDefinitionFile"
                $ResourceDatum = New-DatumStructure -DefinitionFile $DatumDefinitionFile 
            }
            else {
                #Loading Default Datum structure
                Write-Debug "Loading data store from $($ResourceConfigDataPath)."
                $ResourceDatum = New-DatumStructure -DatumHierarchyDefinition @{
                    Path = $ResourceConfigDataPath
                }
            }

            $result = Resolve-Datum -PropertyPath $PropertyPath -Node $Node -searchPaths $DatumDefinition.ResolutionPrecedence -DatumStructure $ResourceDatum
        }
        else {
            Write-Warning "`tNo Datum store found"
            break
        }
        
    }

    if($result -or $NullAllowed) {
        $result
    }
    else {
        throw "The lookup returned a Null value, but Null is not specified as Default. This is not allowed."
    }
}
Set-Alias -Name Lookup -Value Resolve-NodeProperty -scope Global