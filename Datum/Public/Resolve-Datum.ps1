Function Resolve-Datum {
    [cmdletBinding()]
    Param(
        [Parameter(
            Mandatory
        )]
        [string]
        $PropertyPath,

        $Node,
        
        [Parameter(
            Mandatory
        )]
        [string[]]
        $searchPaths,

        [Parameter(
            Mandatory
        )]
        $DatumStructure = $DatumStructure,

        [int]
        $MaxDepth = -1, #infinite by default

        #[ValidateSet('MostSpecific','AllValues','ArrayUnique','Deep')]
        $SearchBehavior = 'MostSpecific'
        
    )

    # Scriptblock in path detection patterns
    $Pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    $PropertySeparator = [IO.Path]::DirectorySeparatorChar
    $splitPattern = [regex]::Escape($PropertySeparator)

    $Depth = 0
    $MergeResult = $null

    # Walk every search path in listed order, and return datum when found at end of path
    foreach ($SearchPrefix in $searchPaths) { #through the hierarchy

        $ArraySb = [System.Collections.ArrayList]@()
        $CurrentSearch = Join-Path $SearchPrefix $PropertyPath

        #extract script block for execution into array, replace by substition strings {0},{1}...
        $newSearch = [regex]::Replace($CurrentSearch, $Pattern, {
                param($match)
                    $expr = $match.groups['sb'].value
                    $index = $ArraySb.Add($expr)
                    "`$({$index})"
            },  @('IgnoreCase', 'SingleLine', 'MultiLine'))
        
        $PathStack = $newSearch -split $splitPattern
        $DatumFound = Resolve-DatumPath -Node $Node -DatumStructure $DatumStructure -PathStack $PathStack -PathVariables $ArraySb
        
        #Stop processing further path at first value in 'MostSpecific' mode (called 'first' in Puppet hiera)
        if ($DatumFound -and ($SearchBehavior -eq 'MostSpecific')) {
            Write-Debug "Depth: $depth; Search Behavior: $SearchBehavior"
            return $DatumFound
        }
        elseif ( $DatumFound ) {

            if(!$MergeResult) { $MergeResult = $DatumFound }
            $allParams = @{
                PropertyPath = $PropertyPath
                Node = $Node
                DatumStructure = $DatumStructure
                SearchPaths = $searchPaths
                MaxDepth = $MaxDepth
                PropertySeparator =$PropertySeparator
                SearchBehavior = $SearchBehavior
            }

            switch ($SearchBehavior) {
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