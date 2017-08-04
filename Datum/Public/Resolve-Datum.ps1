Function Resolve-Datum {
    [cmdletBinding()]
    Param(
        [Parameter(
            Mandatory
        )]
        [string]
        $PropertyPath,

        $Node,

        $Default,
        
        [Parameter(
            Mandatory
        )]
        [string[]]
        $searchPaths,

        [Parameter(
            Mandatory
        )]
        $DatumStructure = $DatumStructure,

        $MaxDepth,

        [ValidateSet('MostSpecific','AllValues')]
        $SearchBehavior = 'MostSpecific'
    )

    $Pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    $Depth = 0
    $MergeResult = $null
    # Walk every search path in listed order, and return datum when found at end of path
    foreach ($SearchPath in $searchPaths) {
        $ArraySb = [System.Collections.ArrayList]@()
        $CurrentSearch = Join-Path $searchPath $PropertyPath
        #extract script block for execution
        $newSearch = [regex]::Replace($CurrentSearch, $Pattern, {
                    param($match)
                    $expr = $match.groups['sb'].value
                    $index = $ArraySb.Add($expr)
                    "`$({$index})"
                },  @('IgnoreCase', 'SingleLine', 'MultiLine'))
        
        $PathStack = $newSearch -split '\\'
        $DatumFound = Resolve-DatumPath -Node $Node -DatumStructure $DatumStructure -PathStack $PathStack -PathVariables $ArraySb
        #Stop processing further path when the Max depth is reached
        # or when you found the first value
        if (($DatumFound -and ($SearchBehavior -eq 'MostSpecific')) -or ($Depth -eq $MaxDepth)) {
            Write-Debug "Depth: $depth; Search Behavior: $SearchBehavior"
            $DatumFound
            return
        }
        elseif($DatumFound -and ($SearchBehavior -eq 'AllValues')) {
            $DatumFound
        }
        #Add Those merge Behaviour:
        # Unique
        # Hash
        # Deep merge
        
        # https://docs.puppet.com/puppet/5.0/hiera_merging.html

        # Configure Merge Behaviour in the Datum structure (as per Puppet hiera)

    }
}