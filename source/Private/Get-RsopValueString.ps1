function Get-RsopValueString
{
    param(
        [Parameter(Mandatory)]
        [object]
        $InputString,

        [Parameter(Mandatory)]
        [string]
        $Key,

        [Parameter()]
        [int]$Depth,

        [Parameter()]
        [switch]$IsArrayValue
    )
    $fileInfo = (Get-RelativeFileName -Path $InputString.__File)

    $i = 120
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
