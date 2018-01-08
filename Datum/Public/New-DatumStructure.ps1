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
        [hashtable]
        $DatumHierarchyDefinition,

        [Parameter(
            Mandatory,
            ParameterSetName = 'FromConfigFile'
        )]
        [io.fileInfo]
        $DefinitionFile
    )

    switch ($PSCmdlet.ParameterSetName) {
        'DatumHierarchyDefinition' {
            if ($DatumHierarchyDefinition.contains('DatumStructure')) {
                Write-debug "Loading Datum from Parameter"
            }
            elseif($DatumHierarchyDefinition.Path) {
                $DatumHierarchyFolder = $DatumHierarchyDefinition.Path
                Write-Debug "Loading default Datum from given path $DatumHierarchyFolder"
            }
            else {
                Write-Warning "Desperate attempt to load Datum from Invocation origin..."
                $CallStack = Get-PSCallstack
                $DatumHierarchyFolder = $CallStack[-1].psscritroot
                Write-Warning " ---> $DatumHierarchyFolder"
            }
        }

        'FromConfigFile' {
            if((Test-Path $DefinitionFile)) {
                $DefinitionFile = (Get-Item $DefinitionFile -ErrorAction Stop)
                Write-Debug "File $DefinitionFile found. Loading..."
                $DatumHierarchyDefinition = Get-FileProviderData $DefinitionFile.FullName
                if(!$DatumHierarchyDefinition.contains('ResolutionPrecedence')) {
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
       
       if($DatumHierarchyDefinition.contains('DatumStructure')) {
           $DatumHierarchyDefinition['DatumStructure'] = $Structures
       }
       else {
           $DatumHierarchyDefinition.add('DatumStructure',$Structures)
       }
    }

    # Define the default hierachy to be the StoreNames, when nothing is specified
    if ($DatumHierarchyFolder -and !$DatumHierarchyDefinition.ResolutionPrecedence) {
        if($DatumHierarchyDefinition.contains('ResolutionPrecedence')) {
            $DatumHierarchyDefinition['ResolutionPrecedence'] = $Structures.StoreName
        }
        else {
            $DatumHierarchyDefinition.add('ResolutionPrecedence',$Structures.StoreName)
        }
    }
    # Adding the Datum Definition to Root object
    $root.add('__Definition',$DatumHierarchyDefinition)

    foreach ($store in $DatumHierarchyDefinition.DatumStructure){
        $StoreParams = @{
            Store =  (ConvertTo-Datum $Store.clone())
            Path  = $store.StoreOptions.Path
        }

        # Accept Module Specification for Store Provider as String (unversioned) or Hashtable
        if($Store.StoreProvider -is [string]) {
            $StoreProviderModule, $StoreProviderName = $store.StoreProvider -split '::'
        }
        else {
            $StoreProviderModule = $Store.StoreProvider.ModuleName
            $StoreProviderName = $Store.StoreProvider.ProviderName
            if($Store.StoreProvider.ModuleVersion) {
                $StoreProviderModule = @{
                    ModuleName = $StoreProviderModule
                    ModuleVersion = $Store.StoreProvider.ModuleVersion
                }
            }
        }

        if(!($Module = Get-Module $StoreProviderModule -ErrorAction SilentlyContinue)) {
            $Module = Import-Module $StoreProviderModule -Force -ErrorAction Stop -PassThru
        }
        $ModuleName = ($Module | Select-Object -First 1).Name

        $NewProvidercmd = Get-Command ("{0}\New-Datum{1}Provider" -f $ModuleName, $StoreProviderName)

        if( $StoreParams.Path -and 
            ![io.path]::IsPathRooted($StoreParams.Path) -and
            $DatumHierarchyFolder
        ) {
            Write-Debug "Replacing Store Path with AbsolutePath"
            $StorePath = Join-Path $DatumHierarchyFolder $StoreParams.Path -Resolve -ErrorAction Stop
            $StoreParams['Path'] = $StorePath
        }

        if ($NewProvidercmd.Parameters.keys -contains 'DatumHierarchyDefinition') {
            Write-Debug "Adding DatumHierarchyDefinition to Store Params"
            $StoreParams.add('DatumHierarchyDefinition',$DatumHierarchyDefinition)
        }

        $storeObject = &$NewProvidercmd @StoreParams
        Write-Debug "Adding key $($store.storeName) to Datum root object"
        $root.Add($store.StoreName,$storeObject)
    }
    
    #return the Root Datum hashtable
    $root
}