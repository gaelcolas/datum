function Resolve-Datum {
    [cmdletBinding()]
    param(
        [Parameter(
            Mandatory
        )]
        [string]
        $PropertyPath,

        [Parameter(
            Position = 1
        )]
        [Alias('Node')]
        $Variable = $ExecutionContext.InvokeCommand.InvokeScript('$Node'),

        [string]
        $VariableName = 'Node',

        [Alias('DatumStructure')]
        $DatumTree = $ExecutionContext.InvokeCommand.InvokeScript('$ConfigurationData.Datum'),

        [Parameter(
            ParameterSetName = 'UseMergeOptions'
        )]
        [Alias('SearchBehavior')]
        $options,

        [string[]]
        [Alias('SearchPaths')]
        $PathPrefixes = $DatumTree.__Definition.ResolutionPrecedence,

        [int]
        $MaxDepth = $(
            if ($MxdDpth = $DatumTree.__Definition.default_lookup_options.MaxDepth) {
                $MxdDpth
            }
            else {
                -1
            })
    )

    # Manage lookup options:
    <#
    default_lookup_options	Lookup_options	options (argument)	Behaviour
                MostSpecific for ^.*
    Present			default_lookup_options + most Specific if not ^.*
        Present		lookup_options + Default to most Specific if not ^.*
            Present	options + Default to Most Specific if not ^.*
    Present	Present		Lookup_options + Default for ^.* if !Exists
    Present		Present	options + Default for ^.* if !Exists
        Present	Present	options override lookup options + Most Specific if !Exists
    Present	Present	Present	options override lookup options + default for ^.*


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

    Write-Debug "Resolve-Datum -PropertyPath <$PropertyPath> -Node $($Node.Name)"
    # Make options an ordered case insensitive variable
    if ($options) {
        $options = [ordered]@{} + $options
    }

    if ( !$DatumTree.__Definition.default_lookup_options ) {
        $default_options = Get-MergeStrategyFromString
        Write-Verbose "  Default option not found in Datum Tree"
    }
    else {
        if ($DatumTree.__Definition.default_lookup_options -is [string]) {
            $default_options = $(Get-MergeStrategyFromString -MergeStrategy $DatumTree.__Definition.default_lookup_options)
        }
        else {
            $default_options = $DatumTree.__Definition.default_lookup_options
        }
        #TODO: Add default_option input validation
        Write-Verbose "  Found default options in Datum Tree of type $($default_options.Strategy)."
    }

    if ( $DatumTree.__Definition.lookup_options) {
        Write-Debug "  Lookup options found."
        $lookup_options = @{} + $DatumTree.__Definition.lookup_options
    }
    else {
        $lookup_options = @{}
    }

    # Transform options from string to strategy hashtable
    foreach ($optKey in ([string[]]$lookup_options.keys)) {
        if ($lookup_options[$optKey] -is [string]) {
            $lookup_options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $lookup_options[$optKey]
        }
    }

    foreach ($optKey in ([string[]]$options.keys)) {
        if ($options[$optKey] -is [string]) {
            $options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $options[$optKey]
        }
    }

    # using options if specified or lookup_options otherwise
    if (!$options) {
        $options = $lookup_options
    }

    # Add default strategy for ^.* if not present, at the end
    if (([string[]]$Options.keys) -notcontains '^.*') {
        # Adding Default flag
        $default_options['Default'] = $true
        $options.add('^.*', $default_options)
    }

    # Create the variable to be used as Pivot in prefix path
    if ( $Variable -and $VariableName ) {
        Set-Variable -Name $VariableName -Value $Variable -Force
    }

    # Scriptblock in path detection patterns
    $Pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    $PropertySeparator = [IO.Path]::DirectorySeparatorChar
    $splitPattern = [regex]::Escape($PropertySeparator)

    $Depth = 0
    $MergeResult = $null

    # Get the strategy for this path, to be used for merging
    $StartingMergeStrategy = Get-MergeStrategyFromPath -PropertyPath $PropertyPath -Strategies $options

    # Walk every search path in listed order, and return datum when found at end of path
    foreach ($SearchPrefix in $PathPrefixes) {
        #through the hierarchy

        $ArraySb = [System.Collections.ArrayList]@()
        $CurrentSearch = Join-Path $SearchPrefix $PropertyPath
        Write-Verbose ''
        Write-Verbose " Lookup <$CurrentSearch> $($Node.Name)"
        #extract script block for execution into array, replace by substition strings {0},{1}...
        $newSearch = [regex]::Replace($CurrentSearch, $Pattern, {
                param($match)
                $expr = $match.groups['sb'].value
                $index = $ArraySb.Add($expr)
                "`$({$index})"
            }, @('IgnoreCase', 'SingleLine', 'MultiLine'))

        $PathStack = $newSearch -split $splitPattern
        # Get value for this property path
        $DatumFound = Resolve-DatumPath -Node $Node -DatumTree $DatumTree -PathStack $PathStack -PathVariables $ArraySb

        if ($DatumFound -is [DatumProvider]) {
            $DatumFound = $DatumFound.ToHashTable()
        }
        
        Write-Debug "  Depth: $depth; Merge options = $($options.count)"

        #Stop processing further path at first value in 'MostSpecific' mode (called 'first' in Puppet hiera)
        if ($null -ne $DatumFound -and ($StartingMergeStrategy.Strategy -match '^MostSpecific|^First')) {
            return $DatumFound
        }
        elseif ($null -ne $DatumFound) {

            if ($null -eq $MergeResult) {
                $MergeResult = $DatumFound
            }
            else {
                $MergeParams = @{
                    StartingPath    = $PropertyPath
                    ReferenceDatum  = $MergeResult
                    DifferenceDatum = $DatumFound
                    Strategies      = $options
                }
                $MergeResult = Merge-Datum @MergeParams
            }
        }

        #if we've reached the Maximum Depth allowed, return current result and stop further execution
        if ($Depth -eq $MaxDepth) {
            Write-Debug "  Max depth of $MaxDepth reached. Stopping."
            Write-Output $MergeResult -NoEnumerate
            return
        }
    }
    Write-Output $MergeResult -NoEnumerate
}
