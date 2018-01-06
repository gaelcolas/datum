Function Resolve-Datum {
    [cmdletBinding()]
    Param(
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
                if($MxdDpth = $DatumTree.__Definition.default_lookup_options.MaxDepth) { 
                    $MxdDpth 
                } 
                else {
                    -1
                })
    )

    # Manage lookup options:
    <#
    default_lookup_options	Lookup_options	options (argument)	Behaviour
    Absent	Absent	Absent	MostSpecific for ^.*
    Present	Absent	Absent	default_lookup_options + most Specific if not ^.*
    Absent	Present	Absent	lookup_options + Default to most Specific if not ^.*
    Absent	Absent	Present	options + Default to Most Specific if not ^.*
    Present	Present	Absent	Lookup_options + Default for ^.* if !Exists
    Present	Absent	Present	options + Default for ^.* if !Exists
    Absent	Present	Present	options override lookup options + Most Specific if !Exists
    Present	Present	Present	options override lookup options + default for ^.*
    
    +========================+================+====================+============================================================+
    | default_lookup_options | Lookup_options | options (argument) |                         Behaviour                          |
    +========================+================+====================+============================================================+
    | Absent                 | Absent         | Absent             | MostSpecific for ^.*                                       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Absent         | Absent             | default_lookup_options + most Specific if not ^.*          |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Absent                 | Present        | Absent             | lookup_options + Default to most Specific if not ^.*       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Absent                 | Absent         | Present            | options + Default to Most Specific if not ^.*              |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Present        | Absent             | Lookup_options + Default for ^.* if !Exists                |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Absent         | Present            | options + Default for ^.* if !Exists                       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Absent                 | Present        | Present            | options override lookup options + Most Specific if !Exists |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Present        | Present            | options override lookup options + default for ^.*          |
    +------------------------+----------------+--------------------+------------------------------------------------------------+

    #>
    
        
    # https://docs.puppet.com/puppet/5.0/hiera_merging.html
    # Configure Merge Behaviour in the Datum structure (as per Puppet hiera)

    if( !$DatumTree.__Definition.default_lookup_options ) {
        $default_options = [ordered]@{
            '^.*' = @{
                strategy = 'MostSpecific'
            }
        }
        Write-Verbose "Default option not found in Datum Tree"
    }
    else {
        if($DatumTree.__Definition.default_lookup_options -is [string]) {
            $default_options =  $(Get-MergeStrategyFromString -MergeStrategy $DatumTree.__Definition.default_lookup_options)
        }
        else {
            $default_options = $DatumTree.__Definition.default_lookup_options
        }
        Write-Verbose "Found default options in Datum Tree of type $($default_options.Strategy)."
    }

    if( $lookup_options = $DatumTree.__Definition.lookup_options) {
        Write-Debug "Lookup options found."
    }
    else {
        $lookup_options = @{}
    }

    # Transform options from string to strategy hashtable
    foreach ($optKey in $lookup_options.keys) {
        if($lookup_options[$optKey] -is [string]) {
            $lookup_options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $lookup_options[$optKey]
        }
    }

    foreach ($optKey in $options.keys) {
        if($options[$optKey] -is [string]) {
            $options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $options[$optKey]
        }
    }

    # using options if specified or lookup_options otherwise 
    if (!$options) {
        $options = $lookup_options
    }

    # Add default strategy for ^.* if not present
    if($Options.keys -notcontains '^.*') {
        $options.add('^.*',$default_options)
    }

    # Create the variable to be used as Pivot in prefix path
    if( $Variable -and $VariableName ) {
        Set-Variable -Name $VariableName -Value $Variable -Force
    }

    # Scriptblock in path detection patterns
    $Pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    $PropertySeparator = [IO.Path]::DirectorySeparatorChar
    $splitPattern = [regex]::Escape($PropertySeparator)

    $Depth = 0
    $MergeResult = $null

    # Get the strategy for this path, to be used for merging
    $StartingMergeStrategy = Get-MergeStrategyFromPath -Path $PropertyPath -Strategies $options

    # Walk every search path in listed order, and return datum when found at end of path
    foreach ($SearchPrefix in $PathPrefixes) { #through the hierarchy

        $ArraySb = [System.Collections.ArrayList]@()
        $CurrentSearch = Join-Path $SearchPrefix $PropertyPath
        Write-Verbose ''
        Write-Verbose "Searching: $CurrentSearch"
        #extract script block for execution into array, replace by substition strings {0},{1}...
        $newSearch = [regex]::Replace($CurrentSearch, $Pattern, {
                param($match)
                    $expr = $match.groups['sb'].value
                    $index = $ArraySb.Add($expr)
                    "`$({$index})"
            },  @('IgnoreCase', 'SingleLine', 'MultiLine'))
        
        $PathStack = $newSearch -split $splitPattern
        # Get value for this property path
        $DatumFound = Resolve-DatumPath -Node $Node -DatumTree $DatumTree -PathStack $PathStack -PathVariables $ArraySb
        
        Write-Debug "Depth: $depth; Merge Behavior: $($options|Convertto-Json|Out-String)"
        
        #Stop processing further path at first value in 'MostSpecific' mode (called 'first' in Puppet hiera)
        if ($DatumFound -and ($StartingMergeStrategy.Strategy -eq 'MostSpecific')) {
            return $DatumFound
        }
        elseif ( $DatumFound ) {

            if(!$MergeResult) {
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
            Write-Debug "Max depth of $MaxDepth reached. Stopping."
            return $MergeResult
        }
    }
    $MergeResult
}