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
        $options = $DatumTree.__Definition.default_lookup_options,

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

    if(!$options) {
        $options = @{
            '' = 'MostSpecific'
        }    
    }
    
    if($Variable -and $VariableName) {
        Set-Variable -Name $VariableName -Value $Variable -Force
    }

    # Scriptblock in path detection patterns
    $Pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    $PropertySeparator = [IO.Path]::DirectorySeparatorChar
    $splitPattern = [regex]::Escape($PropertySeparator)

    $Depth = 0
    $MergeResult = $null

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
        $DatumFound = Resolve-DatumPath -Node $Node -DatumTree $DatumTree -PathStack $PathStack -PathVariables $ArraySb
        
        #Stop processing further path at first value in 'MostSpecific' mode (called 'first' in Puppet hiera)
        Write-Debug "Depth: $depth; Merge Behavior: $($options|Convertto-Json|Out-String)"
        if ($DatumFound -and ($options -eq 'MostSpecific' -or ($options.'' -eq 'MostSpecific'))) {
            return $DatumFound
        }
        elseif ( $DatumFound ) {

            if(!$MergeResult) { $MergeResult = $DatumFound }
            $allParams = @{
                PropertyPath = $PropertyPath
                Node = $Node
                DatumTree = $DatumTree
                PathPrefixes = $PathPrefixes
                MaxDepth = $MaxDepth
                PropertySeparator =$PropertySeparator
                options = $options
            }

            switch ($options) {
                'AllValues' {
                    $DatumFound
                    break
                }

                'Hash' {
                    Merge-Hashtable -ReferenceHashtable $MergeResult -DifferenceHashtable $DatumFound 
                    break
                }

                'deep' {

                }

                'ArrayOfUniqueHashByPropertyName' {

                }
            }
        }

        #if we've reached the Maximum Depth allowed, return current result and stop further exectution
        if ($Depth -eq $MaxDepth) {
            Write-Debug "Max depth of $MaxDepth reached. Stopping."
            return $MergeResult
        }
        
        # https://docs.puppet.com/puppet/5.0/hiera_merging.html
        # Configure Merge Behaviour in the Datum structure (as per Puppet hiera)

    }
}