Class DatumTree : System.Collections.Specialized.OrderedDictionary {

    hidden $ContextConfigFile
    hidden [System.Collections.Specialized.OrderedDictionary] $DatumConfigs = [ordered]@{}
    hidden [string] $DefaultContext
    hidden $_contexts
    hidden $_contextNames

    DatumTree($configFile) {
        Write-Debug "File: $ConfigFile"
        $ConfigFile = Get-Item $ConfigFile -ErrorAction Stop
        $this.ContextConfigFile = $configFile.FullName
        $DatumRootFolder = $ConfigFile.Directory

        # load each datum config as context store
        if ($contextsInFile = (Get-FileProviderData -Path $configFile).contexts) {
            $contextNames = [string[]]$contextsInFile.keys.Where{$_ -ne 'default'}

            if (-not ($this.DefaultContext = $contextsInFile.default)) {
                $this.DefaultContext = $contextNames[0]
            }
            else {
                $contextNames = $contextNames | Sort-Object {$_ -eq $this.DefaultContext} -Descending
            }
            $this._contextNames = $contextNames

            # Load the config files as a provider (so we can use lookup/caching/refresh)
            $Configs = $contextNames.Foreach{
                Write-Verbose "Context: $_"
                $ConfigPath = $contextsInFile.($_).DefinitionFile
                if([io.path]::IsPathRooted($ConfigPath)) {
                    $ConfigPath
                } else {
                    Join-Path -Path $DatumRootFolder -ChildPath $ConfigPath -Resolve -ErrorAction Stop
                }
            }

            $this._Contexts = New-DatumFileProvider -Path $Configs
        }
    }

    LoadContextStores($Context) {
        $DatumStores = Lookup -PropertyPath 'DatumStores' -DatumTree $this._Contexts -Node @{} -SearchPaths $Context
    }

    LoadStores() {
        # load all stores
        
        foreach ($store in $DatumStores){
            $StoreParams = @{
                Store =  (ConvertTo-Datum ([hashtable]$Store).clone())
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
            $this.Add($store.StoreName,$storeObject)
        }
    }
}