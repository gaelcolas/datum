function Get-FileProviderData {
    [CmdletBinding()]
    Param(
        $Path,

        [AllowNull()]
        $DatumHandlers = @{}
    )
    Write-Verbose "Getting File Provider Data for Path: $Path"
    $File = Get-Item -Path $Path
    switch ($File.Extension) {
        '.psd1' { Import-PowerShellDataFile $File           | ConvertTo-Datum -DatumHandlers $DatumHandlers }
        '.json' { ConvertFrom-Json (Get-Content -Raw $Path) | ConvertTo-Datum -DatumHandlers $DatumHandlers }
        '.yml'  { ConvertFrom-Yaml (Get-Content -raw $Path) -ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers }
        
        Default { Get-Content -Raw $Path }
    }
}