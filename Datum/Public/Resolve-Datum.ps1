Function Resolve-Datum {
    [cmdletBinding()]
    Param(
        [string]
        $PropertyPath = 'DSCPULLSRV\ConfigurationPath',
        
        [string[]]
        $searchPaths = @(
            'AllNodes\<%= $CurrentNode.where{$_.Name -eq $Node.Name}%>\Services', #AllNodes is Array of Nodes
            'AllNodes\<%= $CurrentNode.where{$_.Name -eq "All"}%>\Services',
            'SiteData\<%= $CurrentNode.($Node.Location)%>\Services', #SiteData is an Object (key/val)
            'SiteData\All\Services',
            'Services',
            'Services\All'
                        ),

        $Databag = $ConfigurationData,

        [hashtable]
        $Node = $Node,

        [switch]
        $AllValues
    )

    $Pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    foreach ($SearchPath in $searchPaths) {
        $ArraySb = [System.Collections.ArrayList]@()
        $CurrentSearch = Join-Path $searchPath $PropertyPath
        $newSearch = [regex]::Replace($CurrentSearch, $Pattern, {
                    param($match)
                    $expr = $match.groups['sb'].value
                    $index = $ArraySb.Add($expr)
                    "`$({$index})"
                },  @('IgnoreCase', 'SingleLine', 'MultiLine'))
        
        $PathStack = $newSearch -split '\\'
        Resolve-DatumPath -Node $Node -DatabagNode $Databag -PathStack $PathStack -PathVariables $ArraySb
    }
}