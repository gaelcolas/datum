#Requires -module powershell-yaml
#Using Module Datum

function Get-FileProviderData {
    [CmdletBinding()]
    Param(
        $Path
    )

    $File = Get-Item -Path $Path
    switch ($File.Extension) {
        '.psd1' { Import-PowerShellDataFile $File }
        '.json' { Get-Content -Raw $Path | ConvertFrom-Json | ConvertTo-Hashtable }
        '.yml'  { convertfrom-yaml (Get-Content -raw $Path) | ConvertTo-Hashtable }
    }
}