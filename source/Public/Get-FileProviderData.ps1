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
        $data = switch ($file.Extension)
        {
            '.psd1'
            {
                Import-PowerShellDataFile -Path $file | ConvertTo-Datum -DatumHandlers $DatumHandlers
            }
            { $_ -in @('.json', '.yml', '.yaml') }
            {
                try
                {
                    ConvertFrom-Yaml -Yaml (Get-Content -Path $Path -Encoding $Encoding -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
                }
                catch
                {
                    if ($file.Extension -eq '.json')
                    {
                        Write-Error -Message "Failed to parse JSON file '$Path'. Verify the file contains valid JSON. Original error: $($_.Exception.Message)" -ErrorAction Stop
                    }
                    else
                    {
                        throw
                    }
                }
            }
            Default
            {
                Write-Verbose -Message "File extension $($file.Extension) not supported. Defaulting on RAW."
                Get-Content -Path $Path -Encoding $Encoding -Raw
            }
        }

        $script:FileProviderDataCache[$file.FullName] = @{
            Metadata = $file
            Value    = $data
        }
        , $data
    }
}
