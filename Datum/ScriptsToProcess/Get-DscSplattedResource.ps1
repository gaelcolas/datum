function Get-DscSplattedResource {
    [CmdletBinding()]
    Param(
        [String]
        $ResourceName,

        [String]
        $ExecutionName,

        [hashtable]
        $Properties
    )
    
    $stringBuilder = [System.Text.StringBuilder]::new()
    $null = $stringBuilder.AppendLine("Param([hashtable]`$Parameters)")
    $null = $stringBuilder.AppendLine(" $ResourceName $ExecutionName { ")
    foreach($PropertyName in $Properties.keys) {
        $null = $stringBuilder.AppendLine("$PropertyName = `$Parameters['$PropertyName']")
    }
    $null = $stringBuilder.AppendLine("}")
    Write-Debug ("Generated Resource Block = {0}" -f $stringBuilder.ToString())
    [scriptblock]::Create($stringBuilder.ToString()).Invoke($Properties)
}
Set-Alias -Name x -Value Get-DscSplattedResource
#Export-ModuleMember -Alias x

<#

ipmo -Force ..\..\Datum.psd1
. .\demo3.ps1
MyConfiguration -ConfigurationData $mydata -verbose

#>