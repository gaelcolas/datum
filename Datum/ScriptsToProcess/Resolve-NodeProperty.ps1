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
        Push-Location $MyInvocation.PSScriptRoot
        $ResourceConfigDataPath = (Join-Path $MyInvocation.PSScriptRoot 'ConfigData')
        if(Test-Path $ResourceConfigDataPath) {
            $DatumDefinitionFile = Join-Path $ResourceConfigDataPath 'Datum.yml'
            if(Test-Path $DatumDefinitionFile) {
                Write-Debug "Datum File Path: $DatumDefinitionFile"
                $DatumDefinition = Get-FileProviderData -Path $DatumDefinitionFile
                Write-Debug "Datum Definition: $($DatumDefinition | Convertto-Json)"
                $ResourceDatum = New-DatumStructure $DatumDefinition 
            }
            else { #Loading Default Datum structure
                $DatumDefinition = @{
                    DatumStructure = @{
                        StoreName = "common"
                        StoreProvider = "Datum::File"
                        StoreOptions = @{
                            DataDir = "./ConfigData/Common"
                        }
                    }
                    ResolutionPrecedence = @(
                        'common'
                    )
                }
            }
            $ResourceDatum = New-DatumStructure $DatumDefinition
            $result = Resolve-Datum -PropertyPath $PropertyPath -Node $Node -searchPaths $DatumDefinition.ResolutionPrecedence -DatumStructure $ResourceDatum
        }
        Pop-Location
        if($result) {
            $result
        }
        else {
            throw "The lookup returned a Null value, but Null is not specified as Default. This is not allowed."
        }
    }

}
Set-Alias -Name Lookup -Value Resolve-NodeProperty