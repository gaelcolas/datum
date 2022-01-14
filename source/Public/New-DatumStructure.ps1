function New-DatumStructure
{
    [OutputType([hashtable])]
    [CmdletBinding(DefaultParameterSetName = 'FromConfigFile')]

    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'DatumHierarchyDefinition')]
        [Alias('Structure')]
        [hashtable]
        $DatumHierarchyDefinition,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromConfigFile')]
        [System.IO.FileInfo]
        $DefinitionFile,

        [Parameter()]
        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'DatumHierarchyDefinition'
        {
            if ($DatumHierarchyDefinition.Contains('DatumStructure'))
            {
                Write-Debug -Message 'Loading Datum from Parameter'
            }
            elseif ($DatumHierarchyDefinition.Path)
            {
                $datumHierarchyFolder = $DatumHierarchyDefinition.Path
                Write-Debug -Message "Loading default Datum from given path $datumHierarchyFolder"
            }
            else
            {
                Write-Warning -Message 'Desperate attempt to load Datum from Invocation origin...'
                $callStack = Get-PSCallStack
                $datumHierarchyFolder = $callStack[-1].PSScriptRoot
                Write-Warning -Message " ---> $datumHierarchyFolder"
            }
        }

        'FromConfigFile'
        {
            if ((Test-Path -Path $DefinitionFile))
            {
                $DefinitionFile = (Get-Item -Path $DefinitionFile -ErrorAction Stop)
                Write-Debug -Message "File $DefinitionFile found. Loading..."
                $DatumHierarchyDefinition = Get-FileProviderData -Path $DefinitionFile.FullName -Encoding $Encoding
                if (-not $DatumHierarchyDefinition.Contains('ResolutionPrecedence'))
                {
                    throw 'Invalid Datum Hierarchy Definition'
                }
                $datumHierarchyFolder = $DefinitionFile.Directory.FullName
                $DatumHierarchyDefinition.DatumDefinitionFile = $DefinitionFile
                Write-Debug -Message "Datum Hierachy Parent folder: $datumHierarchyFolder"
            }
            else
            {
                throw 'Datum Hierarchy Configuration not found'
            }
        }
    }

    $root = @{}
    if ($datumHierarchyFolder -and -not $DatumHierarchyDefinition.DatumStructure)
    {
        $structures = foreach ($store in (Get-ChildItem -Directory -Path $datumHierarchyFolder))
        {
            @{
                StoreName     = $store.BaseName
                StoreProvider = 'Datum::File'
                StoreOptions  = @{
                    Path = $store.FullName
                }
            }
        }

        if ($DatumHierarchyDefinition.Contains('DatumStructure'))
        {
            $DatumHierarchyDefinition['DatumStructure'] = $structures
        }
        else
        {
            $DatumHierarchyDefinition.Add('DatumStructure', $structures)
        }
    }

    # Define the default hierachy to be the StoreNames, when nothing is specified
    if ($datumHierarchyFolder -and -not $DatumHierarchyDefinition.ResolutionPrecedence)
    {
        if ($DatumHierarchyDefinition.Contains('ResolutionPrecedence'))
        {
            $DatumHierarchyDefinition['ResolutionPrecedence'] = $structures.StoreName
        }
        else
        {
            $DatumHierarchyDefinition.Add('ResolutionPrecedence', $structures.StoreName)
        }
    }
    # Adding the Datum Definition to Root object
    $root.Add('__Definition', $DatumHierarchyDefinition)

    foreach ($store in $DatumHierarchyDefinition.DatumStructure)
    {
        $storeParams = @{
            Store    = (ConvertTo-Datum ([hashtable]$store).clone())
            Path     = $store.StoreOptions.Path
            Encoding = $Encoding
        }

        # Accept Module Specification for Store Provider as String (unversioned) or Hashtable
        if ($store.StoreProvider -is [string])
        {
            $storeProviderModule, $storeProviderName = $store.StoreProvider -split '::'
        }
        else
        {
            $storeProviderModule = $store.StoreProvider.ModuleName
            $storeProviderName = $store.StoreProvider.ProviderName
            if ($store.StoreProvider.ModuleVersion)
            {
                $storeProviderModule = @{
                    ModuleName    = $storeProviderModule
                    ModuleVersion = $store.StoreProvider.ModuleVersion
                }
            }
        }

        if (-not ($module = Get-Module -Name $storeProviderModule -ErrorAction SilentlyContinue))
        {
            $module = Import-Module $storeProviderModule -Force -ErrorAction Stop -PassThru
        }
        $moduleName = ($module | Where-Object { $_.ExportedCommands.Keys -match 'New-Datum(\w+)Provider' }).Name

        $newProviderCmd = Get-Command ('{0}\New-Datum{1}Provider' -f $moduleName, $storeProviderName)

        if ($storeParams.Path -and -not [System.IO.Path]::IsPathRooted($storeParams.Path) -and $datumHierarchyFolder)
        {
            Write-Debug -Message 'Replacing Store Path with AbsolutePath'
            $storePath = Join-Path -Path $datumHierarchyFolder -ChildPath $storeParams.Path -Resolve -ErrorAction Stop
            $storeParams['Path'] = $storePath
        }

        if ($newProviderCmd.Parameters.Keys -contains 'DatumHierarchyDefinition')
        {
            Write-Debug -Message 'Adding DatumHierarchyDefinition to Store Params'
            $storeParams.Add('DatumHierarchyDefinition', $DatumHierarchyDefinition)
        }

        $storeObject = &$newProviderCmd @storeParams
        Write-Debug -Message "Adding key $($store.StoreName) to Datum root object"
        $root.Add($store.StoreName, $storeObject)
    }

    #return the Root Datum hashtable
    $root
}
