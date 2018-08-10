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
                    $result = ConvertFrom-Yaml (Get-Content -Path $Path -Raw) -Ordered | Add-Member -MemberType NoteProperty -Name ProviderURI -Value $Path -Force -PassThru | ConvertTo-Datum -DatumHandlers $DatumHandlers
                    Write-Output $result -NoEnumerate
                }
                
                Default { Get-Content -Path $Path -Raw }
            }

            $script:FileProviderDataCache[$File.FullName] = @{
                Metadata = $File
                Value = $data
            }
            Write-Output $data -NoEnumerate
        }
    }
}