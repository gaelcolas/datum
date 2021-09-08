function Get-FileProviderData
{
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHandlers = @{},

        [Parameter()]
        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
    )

    if (-not $script:FileProviderDataCache)
    {
        $script:FileProviderDataCache = @{}
    }

    $file = Get-Item -Path $Path
    if ($script:FileProviderDataCache.ContainsKey($file.FullName) -and
        $file.LastWriteTime -eq $script:FileProviderDataCache[$file.FullName].Metadata.LastWriteTime)
    {
        Write-Verbose -Message "Getting File Provider Cache for Path: $Path"
        , $script:FileProviderDataCache[$file.FullName].Value
    }
    else
    {
        Write-Verbose -Message "Getting File Provider Data for Path: $Path"
        try
        {
            $data = switch ($file.Extension)
            {
                '.psd1'
                {
                    Import-PowerShellDataFile -Path $file | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                '.json'
                {
                    ConvertFrom-Json -InputObject (Get-Content -Path $Path -Encoding $Encoding -Raw) | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                '.yml'
                {
                    ConvertFrom-Yaml -Yaml (Get-Content -Path $Path -Encoding $Encoding -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                '.yaml'
                {
                    ConvertFrom-Yaml -Yaml (Get-Content -Path $Path -Encoding $Encoding -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                Default
                {
                    Write-Verbose -Message "File extension $($file.Extension) not supported. Defaulting on RAW."
                    Get-Content -Path $Path -Encoding $Encoding -Raw
                }
            }
        }
        catch
        {
            Write-Warning "'ConvertTo-Datum' threw an error reading $($File.FullName): $($_.Exception.Message)"
        }

        $script:FileProviderDataCache[$file.FullName] = @{
            Metadata = $file
            Value    = $data
        }
        , $data
    }
}
