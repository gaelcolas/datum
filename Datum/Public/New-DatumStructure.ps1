<#
    Datum Structure is a PSCustomObject 
     To that object we add DatumStores as Script Properties/Class instances
      Those Properties embed the mechanism to call the container hierarchy and the RAW value of the items
       The format of the item defines its method of conversion from raw to Object 
#>

function New-DatumStructure {
    [CmdletBinding(
        DefaultParameterSetName = 'FromConfigFile'
    )]

    Param (
        [Parameter(
            Mandatory,
            ParameterSetName = 'DatumHierarchyDefinition'
        )]
        [Alias('Structure')]
        $DatumHierarchyDefinition,

        [Parameter(
            Mandatory,
            ParameterSetName = 'FromConfigFile'
        )]
        [io.fileInfo]
        $DefinitionFile = 'Datum.*'
    )

    switch ($PSCmdlet.ParameterSetName) {
        #'DatumHierarchyDefinition' {
        #    $CallStack = Get-PSCallstack
        #    $DatumHierarchyFolder = $CallStack[-1].psscritroot
        #}

        'FromConfigFile' {
            if((Test-Path $DefinitionFile)) {
                $DefinitionFile = (Get-Item $DefinitionFile -ErrorAction Stop)
                Write-Debug "File $DefinitionFile found. Loading..."
                $DatumHierarchyDefinition = Get-FileProviderData $DefinitionFile.FullName
                if(!$DatumHierarchyDefinition.ContainsKey('ResolutionPrecedence')) {
                    Throw 'Invalid Datum Hierarchy Definition'
                }
                $DatumHierarchyFolder = $DefinitionFile.directory.FullName
                Write-Debug "Datum Hierachy Parent folder: $DatumHierarchyFolder"
            }
            else {
                Throw "Datum Hierarchy Configuration not found"
            }
        }
    }


    $root = @{}
    if($DatumHierarchyFolder -and !$DatumHierarchyDefinition.DatumStructure) {
       $Structures = foreach ($Store in (Get-ChildItem -Directory -Path $DatumHierarchyFolder)) {
           @{
               StoreName = $Store.BaseName
               StoreProvider = 'Datum::File'
               StoreOptions = @{
                   Path = $Store.FullName
               }
           }
       }
       if($DatumHierarchyDefinition.containsKey('DatumStructure')) {
           $DatumHierarchyDefinition['DatumStructure'] = $Structures
       }
       else {
           $DatumHierarchyDefinition.add('DatumStructure',$Structures)
       }
    }

    foreach ($store in $DatumHierarchyDefinition.DatumStructure){
        #$StoreParams = Convertto-hashtable $Store.StoreOptions
        $StoreParams = $Store.StoreOptions
        $cmd = Get-Command ("{0}\New-Datum{1}Provider" -f ($store.StoreProvider -split '::'))

        if( $StoreParams.Path -and 
            ![io.path]::IsPathRooted($StoreParams.Path) -and
            $DatumHierarchyFolder
        ) {
            Write-Debug "Replacing Store Path with AbsolutePath"
            $StoreParams['Path'] = Join-Path $DatumHierarchyFolder $StoreParams.Path -Resolve -ErrorAction Stop
        }
        $storeObject = &$cmd @StoreParams
        Write-Debug "Adding key $($store.storeName) to Datum root object"
        $root.Add($store.StoreName,$storeObject)
    }
    
    ([PSCustomObject]$root) | Add-Member -PassThru -MemberType NoteProperty -Name __Definition -Value $DatumHierarchyDefinition
}