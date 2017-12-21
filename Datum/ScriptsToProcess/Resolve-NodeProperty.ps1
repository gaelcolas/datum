function Global:Resolve-NodeProperty {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory,
            Position = 0
        )]
        $PropertyPath,

        [Parameter(
            Position = 1
        )]
        [AllowNull()]
        $DefaultValue,

        [Parameter(
            Position = 3
        )]
        $Node = $ExecutionContext.InvokeCommand.InvokeScript('$Node'),

        [Alias('DatumStructure')]
        $DatumTree = $ExecutionContext.InvokeCommand.InvokeScript('$ConfigurationData.Datum'),

        [Alias('SearchBehavior')]
        $options = $DatumTree.__Definition.lookup_options,

        [string[]]
        $SearchPaths = $DatumTree.__Definition.ResolutionPrecedence,
        
        [Parameter(
            Position = 5
        )]
        [int]
        $MaxDepth = $(if($MxdDpth = $DatumTree.__Definition.default_lookup_options.MaxDepth) { $MxdDpth } else { -1 })
    )

    # Null result should return an exception, unless defined as Default value
    $NullAllowed = $false
    $ResolveDatumParams = ([hashtable]$PSBoundParameters).Clone()
    foreach ($removeKey in $PSBoundParameters.keys.where{$_ -in @('DefaultValue','Node')}) {
        $ResolveDatumParams.remove($removeKey)
    }
    
    if($Node) {
        $ResolveDatumParams.Add('Variable',$Node)
        $ResolveDatumParams.Add('VariableName','Node')
    }

    if($result = Resolve-Datum @ResolveDatumParams) {
        Write-Verbose "`tResult found for $PropertyPath"
    }
    elseif($DefaultValue) {
        $result = $DefaultValue
        Write-Debug "`t`tDefault Found"
    }
    elseif($PSboundParameters.containsKey('DefaultValue') -and $null -eq $DefaultValue) {
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
Set-Alias -Name Resolve-DscProperty -Value Resolve-NodeProperty -scope Global