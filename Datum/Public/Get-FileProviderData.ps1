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
            $script:FileProviderDataCache[$File.FullName].Value
        }
        else {
            Write-Verbose "Getting File Provider Data for Path: $Path"
            $Data = switch ($File.Extension) {
                '.psd1' { Import-PowerShellDataFile $File           | ConvertTo-Datum -DatumHandlers $DatumHandlers }
                '.json' { ConvertFrom-Json (Get-Content -Raw $Path) | ConvertTo-Datum -DatumHandlers $DatumHandlers }
                '.yml'  { ConvertFrom-Yaml (Get-Content -raw $Path) -ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers }
                '.csv'  {
                    $listSeparator = $MyInvocation.MyCommand.Module.PrivateData.CsvListSeparator
                    $innerListSeparator = $MyInvocation.MyCommand.Module.PrivateData.CsvInnerListSeperator

                    if (-not $listSeparator -or -not $innerListSeparator)
                    {
                        Write-Error "Cannot import CSV file '$Path' as the 'ListSeparator' or 'InnerListSeparator'"
                        return
                    }
                    $param = @{
                        Path        = $Path
                        ErrorAction = 'Stop'
                        Delimiter   = if ($listSeparator) { $listSeparator } else { (Get-UICulture).TextInfo.ListSeparator }
                    }
                    if ($innerListSeparator) {
                        $param.Add('InnerDelimiter', $innerListSeparator)
                    }
                    
                    Import-CsvAsHashTable @param | ConvertTo-Datum -DatumHandlers $DatumHandlers 
                }
                Default { Get-Content -Raw $Path }
            }
            $script:FileProviderDataCache[$File.FullName] = @{
                Metadata = $File
                Value = $Data
            }
            $Data
        }
    }
}