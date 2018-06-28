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
                    
                    $data = Get-Content -Path $Path | ConvertFrom-Csv -Delimiter $listSeparator | ConvertTo-Datum -DatumHandlers $DatumHandlers
                    for ($i = 0; $i -lt $data.Count; $i++)
                    {
                        for ($j = 0; $j -lt $data[$i].Keys.Count; $j++)
                        {
                            if ($data[$i]."$(([array]$data[$i].Keys)[$j])".Contains($innerListSeparator))
                            {
                                $data[$i]."$(([array]$data[$i].Keys)[$j])" = $data[$i]."$(([array]$data[$i].Keys)[$j])" -split $innerListSeparator
                            }
                        }                        
                    }
                    $data
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