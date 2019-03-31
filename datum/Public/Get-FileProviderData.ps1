function Get-FileProviderData {
    [CmdletBinding()]
    Param(
        $Path,

        [AllowNull()]
        $DatumHandlers = @{}
    )

    begin {
        if(!$script:FileProviderDataCache) {
            $script:FileProviderDataCache = @{}
        }
    }

    process {
        $File = Get-Item -Path $Path
        if($script:FileProviderDataCache.ContainsKey($File.FullName) -and
        $File.LastWriteTime -eq $script:FileProviderDataCache[$File.FullName].Metadata.LastWriteTime) {
            Write-Verbose "Getting File Provider Cache for Path: $Path"
            ,$script:FileProviderDataCache[$File.FullName].Value
        } else {
            Write-Verbose "Getting File Provider Data for Path: $Path"
            $data = switch ($File.Extension) {
                '.psd1' {
                    Import-PowerShellDataFile -Path $File | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                '.json' {
                    ConvertFrom-Json (Get-Content -Path $Path -Raw) | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                '.yml' {
                    ConvertFrom-Yaml (Get-Content -Path $Path -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                Default {
                    Get-Content -Path $Path -Raw
                }
            }

            $script:FileProviderDataCache[$File.FullName] = @{
                Metadata = $File
                Value = $data
            }
            ,$data
        }
    }
}