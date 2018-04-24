function Import-CsvAsHashTable {
    [OutputType([System.Collections.Hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$KeyColumn,

        [char]$Delimiter = (Get-UICulture).TextInfo.ListSeparator,

        [char]$InnerDelimiter,

        [ValidateSet('Unicode', 'UTF7' , 'UTF8' , 'ASCII', 'UTF32', 'BigEndianUnicode', 'Default', 'OEM')]
        [string]$Encoding = 'Default'
    )

    [void]$PSBoundParameters.Remove('KeyColumn')

    $content = Get-Content -Path $Path -Encoding $Encoding |
        Where-Object { $_ -notlike '#*'}
    $csv = $content | ConvertFrom-Csv -Delimiter $Delimiter
    $properties = $csv | Get-Member -MemberType NoteProperty
    if (-not $KeyColumn) {
        $KeyColumn = ($content | Select-Object -First 1) -split $Delimiter | Select-Object -First 1
    }

    if (-not ($properties | Where-Object Name -eq $KeyColumn)) {
        Write-Error "The given KeyColumn '$KeyColumn' does not exist in CSV file '$Path'."
        return
    }

    if ($csv."$KeyColumn" | Group-Object | Where-Object Count -gt 1) {
        Write-Error "There are duplicate keys in the column '$KeyColumn' in CSV file '$Path'"
        return
    }

    $ht = @{}

    foreach ($item in $csv) {
        $subItems = @{}
        foreach ($property in ($properties | Where-Object Name -ne $KeyColumn)) {
            $propertyValue = $item."$($property.Name)"
            if ($propertyValue -like ($InnerDelimiter)) {
                $values = $propertyValue -split $InnerDelimiter
                $subItems.Add($property.Name, $values)
            }
            else {
                $subItems.Add($property.Name, $propertyValue)
            }
            
        }

        $ht.Add($item."$KeyColumn", $subItems)
    }

    $ht
}