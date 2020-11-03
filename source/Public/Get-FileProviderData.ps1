function Get-FileProviderData {
    [CmdletBinding()]
    Param(
        $Path,

        [AllowNull()]
        $DatumHandlers = @{},

        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
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
                    ConvertFrom-Json (Get-Content -Path $Path -Encoding $Encoding -Raw) | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                '.yml' {
                    ConvertFrom-Yaml (Get-Content -Path $Path -Encoding $Encoding -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                '.yaml' {
                    ConvertFrom-Yaml (Get-Content -Path $Path -Encoding $Encoding -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                Default {
                    Write-verbose "File extension $($File.Extension) not supported. Defaulting on RAW."
                    Get-Content -Path $Path -Encoding $Encoding -Raw
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
