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
            Write-Output $script:FileProviderDataCache[$File.FullName].Value -NoEnumerate
        }
        else {
            Write-Verbose "Getting File Provider Data for Path: $Path"
            $data = switch ($File.Extension) {
                '.psd1' {
                    $result = Import-PowerShellDataFile -Path $File | ConvertTo-Datum -DatumHandlers $DatumHandlers
                    Write-Output $result -NoEnumerate
                }
                '.json' { 
                    $result = ConvertFrom-Json (Get-Content -Path $Path -Raw) | ConvertTo-Datum -DatumHandlers $DatumHandlers
                    Write-Output $result -NoEnumerate
                }
                '.yml'  { 
                    $result = ConvertFrom-Yaml (Get-Content -Path $Path -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
                    Write-Output $result -NoEnumerate
                }
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

                    $result = Get-Content -Path $Path | ConvertFrom-Csv -Delimiter $listSeparator | ConvertTo-Datum -DatumHandlers $DatumHandlers
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
                    Write-Output $result -NoEnumerate
                }
                Default { Get-Content -Path $Path -Raw }
            }

            if ($data -is [System.Collections.IDictionary]) {
                $data.Add('__DatumInternal_Path', $Path)
            }
            $data | Add-Member -Name __DatumInternal_Path -MemberType NoteProperty -Value $Path

            $script:FileProviderDataCache[$File.FullName] = @{
                Metadata = $File
                Value = $data
            }
            Write-Output $data -NoEnumerate
        }
    }
}