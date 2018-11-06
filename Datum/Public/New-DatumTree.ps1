function New-DatumTree {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ParameterSetName = 'DatumHierarchyDefinition'
        )]
        [Alias('Structure')]
        [hashtable]
        $DatumHierarchyDefinition,

        [Parameter(
            Mandatory,
            ParameterSetName = 'FromConfigFile'
        )]
        [io.fileInfo]
        $DefinitionFile
    )
    
    # $Datum
    # $Datum.__config.default = dsc
    # $Datum.__config.DSC
    # $Datum.__config.Packer
    # $Datum.__config.resolution_precedence = 'DSC','Packer'
    # New-DatumFileProvider -Path '.\Datum\tests\Integration\assets\contexts\DSC.Datum.yml', '.\Datum\tests\Integration\assets\contexts\Packer.Datum.yml'


    begin {
        # if it's a folder, try to find Datum.ext
        # then or if it's a file, load file data

        $ConfigEntry = Get-FileProviderData -Path $FileConfig
        if ($ConfigEntry.contexts.contains('default')) {
            $default = $ConfigEntry.default
        }

        $contextNames = @() + $default
        $contextNames += $ConfigEntry.contexts.keys.Where{$_ -ne $default}

        $DatumRoot = [ordered]@{}

    }
}