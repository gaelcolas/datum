function Get-RsopValueString
{
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $InputString,

        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter()]
        [int]$Depth,

        [Parameter()]
        [switch]$IsArrayValue,

        [Parameter()]
        [switch]
        $AddSourceInformation
    )

    if (-not $AddSourceInformation)
    {
        $InputString.psobject.BaseObject
    }
    else
    {
        $fileInfo = (Get-RelativeFileName -Path $InputString.__File)

        $i = if ($env:DatumRsopIndentation)
        {
            $env:DatumRsopIndentation
        }
        else
        {
            120
        }

        $i = if ($IsArrayValue)
        {
            $Depth--
            $i - ("$InputString".Length)
        }
        else
        {
            $i - ($Key.Length + "$InputString".Length)
        }

        $i -= [System.Math]::Max(0, ($depth) * 2)
        "{0}$(if ($fileInfo) { ""{1, $i}""  })" -f $InputString, $fileInfo
    }
}
