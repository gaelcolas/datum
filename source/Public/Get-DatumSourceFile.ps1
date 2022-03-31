function Get-DatumSourceFile
{
    <#
    .SYNOPSIS
        Gets the source file for the given datum.
    .DESCRIPTION

        This command gets the relative source file for the given datum. The source file path
        is relative to the current directory and skips the first directory in the path.

    .EXAMPLE
        PS C:\> Get-DatumSourceFile -Path D:\git\datum\tests\Integration\assets\DscWorkshopConfigData\Roles\DomainController.yml

        This command returns the source file path like this:
            assets\DscWorkshopConfigData\Roles\DomainController

    .INPUTS
        string

    .OUTPUTS
        string
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Path
    )

    if (-not $Path)
    {
        return [string]::Empty
    }

    try
    {
        $p = Resolve-Path -Path $Path -Relative -ErrorAction Stop
        $p = $p -split '\\'
        $p[-1] = [System.IO.Path]::GetFileNameWithoutExtension($p[-1])
        $p[2..($p.Length - 1)] -join '\'
    }
    catch
    {
        Write-Verbose 'Get-DatumSourceFile: nothing to catch here'
    }
}
