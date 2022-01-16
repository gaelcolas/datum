function Resolve-Datum
{
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PropertyPath,

        [Parameter(Position = 1)]
        [Alias('Node')]
        [object]
        $Variable = $ExecutionContext.InvokeCommand.InvokeScript('$Node'),

        [Parameter()]
        [string]
        $VariableName = 'Node',

        [Parameter()]
        [Alias('DatumStructure')]
        [object]
        $DatumTree = $ExecutionContext.InvokeCommand.InvokeScript('$ConfigurationData.Datum'),

        [Parameter(ParameterSetName = 'UseMergeOptions')]
        [Alias('SearchBehavior')]
        [hashtable]
        $Options,

        [Parameter()]
        [Alias('SearchPaths')]
        [string[]]
        $PathPrefixes = $DatumTree.__Definition.ResolutionPrecedence,

        [Parameter()]
        [int]
        $MaxDepth = $(
            if ($mxdDpth = $DatumTree.__Definition.default_lookup_options.MaxDepth)
            {
                $mxdDpth
            }
            else
            {
                -1
            })
    )

    # Manage lookup options:
    <#
    default_lookup_options  Lookup_options  options (argument)  Behaviour
                MostSpecific for ^.*
    Present         default_lookup_options + most Specific if not ^.*
        Present     lookup_options + Default to most Specific if not ^.*
            Present options + Default to Most Specific if not ^.*
    Present Present     Lookup_options + Default for ^.* if !Exists
    Present     Present options + Default for ^.* if !Exists
        Present Present options override lookup options + Most Specific if !Exists
    Present Present Present options override lookup options + default for ^.*


    +========================+================+====================+============================================================+
    | default_lookup_options | Lookup_options | options (argument) |                         Behaviour                          |
    +========================+================+====================+============================================================+
    |                        |                |                    | MostSpecific for ^.*                                       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                |                |                    | default_lookup_options + most Specific if not ^.*          |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    |                        | Present        |                    | lookup_options + Default to most Specific if not ^.*       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    |                        |                | Present            | options + Default to Most Specific if not ^.*              |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Present        |                    | Lookup_options + Default for ^.* if !Exists                |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                |                | Present            | options + Default for ^.* if !Exists                       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    |                        | Present        | Present            | options override lookup options + Most Specific if !Exists |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Present        | Present            | options override lookup options + default for ^.*          |
    +------------------------+----------------+--------------------+------------------------------------------------------------+

    If there's no default options, auto-add default options of mostSpecific merge, and tag as 'default'
    if there's a default options, use that strategy and tag as 'default'
    if the options implements ^.*, do not add Default_options, and do not tag

    1. Defaults to Most Specific
    2. Allow setting your own default, with precedence for non-default options
    3. Overriding ^.* without tagging it as default (always match unless)

    #>

    Write-Debug -Message "Resolve-Datum -PropertyPath <$PropertyPath> -Node $($Node.Name)"
    # Make options an ordered case insensitive variable
    if ($Options)
    {
        $Options = [ordered]@{} + $Options
    }

    if (-not $DatumTree.__Definition.default_lookup_options)
    {
        $default_options = Get-MergeStrategyFromString
        Write-Verbose -Message '  Default option not found in Datum Tree'
    }
    else
    {
        if ($DatumTree.__Definition.default_lookup_options -is [string])
        {
            $default_options = Get-MergeStrategyFromString -MergeStrategy $DatumTree.__Definition.default_lookup_options
        }
        else
        {
            $default_options = $DatumTree.__Definition.default_lookup_options
        }
        #TODO: Add default_option input validation
        Write-Verbose -Message "  Found default options in Datum Tree of type $($default_options.Strategy)."
    }

    if ($DatumTree.__Definition.lookup_options)
    {
        Write-Debug -Message '  Lookup options found.'
        $lookup_options = @{} + $DatumTree.__Definition.lookup_options
    }
    else
    {
        $lookup_options = @{}
    }

    # Transform options from string to strategy hashtable
    foreach ($optKey in ([string[]]$lookup_options.Keys))
    {
        if ($lookup_options[$optKey] -is [string])
        {
            $lookup_options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $lookup_options[$optKey]
        }
    }

    foreach ($optKey in ([string[]]$Options.Keys))
    {
        if ($Options[$optKey] -is [string])
        {
            $Options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $Options[$optKey]
        }
    }

    # using options if specified or lookup_options otherwise
    if (-not $Options)
    {
        $Options = $lookup_options
    }

    # Add default strategy for ^.* if not present, at the end
    if (([string[]]$Options.Keys) -notcontains '^.*')
    {
        # Adding Default flag
        $default_options['Default'] = $true
        $Options.Add('^.*', $default_options)
    }

    # Create the variable to be used as Pivot in prefix path
    if ($Variable -and $VariableName)
    {
        Set-Variable -Name $VariableName -Value $Variable -Force
    }

    # Scriptblock in path detection patterns
    $pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    $propertySeparator = [System.IO.Path]::DirectorySeparatorChar
    $splitPattern = [regex]::Escape($propertySeparator)

    $depth = 0
    $mergeResult = $null

    # Get the strategy for this path, to be used for merging
    $startingMergeStrategy = Get-MergeStrategyFromPath -PropertyPath $PropertyPath -Strategies $Options

    #Invoke datum handlers
    $PathPrefixes = $PathPrefixes | ConvertTo-Datum -DatumHandlers $datum.__Definition.DatumHandlers

    # Walk every search path in listed order, and return datum when found at end of path
    foreach ($searchPrefix in $PathPrefixes)
    {
        #through the hierarchy
        $arraySb = [System.Collections.ArrayList]@()
        $currentSearch = [System.IO.Path]::Combine($searchPrefix, $PropertyPath)
        Write-Verbose -Message ''
        Write-Verbose -Message " Lookup <$currentSearch> $($Node.Name)"
        #extract script block for execution into array, replace by substition strings {0},{1}...
        $newSearch = [regex]::Replace($currentSearch, $pattern, {
                param (
                    [Parameter()]
                    $match
                )
                $expr = $match.groups['sb'].value
                $index = $arraySb.Add($expr)
                "`$({$index})"
            }, @('IgnoreCase', 'SingleLine', 'MultiLine'))

        $pathStack = $newSearch -split $splitPattern
        # Get value for this property path
        $datumFound = Resolve-DatumPath -Node $Node -DatumTree $DatumTree -PathStack $pathStack -PathVariables $arraySb

        if ($datumFound -is [DatumProvider])
        {
            $datumFound = $datumFound.ToOrderedHashTable()
        }

        Write-Debug -Message "  Depth: $depth; Merge options = $($Options.count)"

        #Stop processing further path at first value in 'MostSpecific' mode (called 'first' in Puppet hiera)
        if ($null -ne $datumFound -and ($startingMergeStrategy.Strategy -match '^MostSpecific|^First'))
        {
            return $datumFound
        }
        elseif ($null -ne $datumFound)
        {

            if ($null -eq $mergeResult)
            {
                $mergeResult = $datumFound
            }
            else
            {
                $mergeParams = @{
                    StartingPath    = $PropertyPath
                    ReferenceDatum  = $mergeResult
                    DifferenceDatum = $datumFound
                    Strategies      = $Options
                }
                $mergeResult = Merge-Datum @mergeParams
            }
        }

        #if we've reached the Maximum Depth allowed, return current result and stop further execution
        if ($depth -eq $MaxDepth)
        {
            Write-Debug "  Max depth of $MaxDepth reached. Stopping."
            , $mergeResult
            return
        }
    }
    , $mergeResult
}
