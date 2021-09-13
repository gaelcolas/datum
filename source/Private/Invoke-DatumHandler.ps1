function Invoke-DatumHandler
{
    param (
        [Parameter(Mandatory)]
        [object]
        $InputObject,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHandlers,

        [Parameter()]
        [ref]$Result
    )
    $return = $false

    foreach ($handler in $DatumHandlers.Keys)
    {
        if ($DatumHandlers.$handler.SkipDuringLoad -and (Get-PSCallStack).Command -contains 'Get-FileProviderData')
        {
            continue
        }

        $FilterModule, $FilterName = $Handler -split '::'
        if (-not (Get-Module $FilterModule))
        {
            Import-Module $FilterModule -Force -ErrorAction Stop
        }
        $filterCommand = Get-Command -ErrorAction SilentlyContinue ('{0}\Test-{1}Filter' -f $FilterModule, $FilterName)
        if ($filterCommand -and ($InputObject | &$filterCommand))
        {
            try
            {
                if ($actionCommand = Get-Command -Name ('{0}\Invoke-{1}Action' -f $FilterModule, $FilterName) -ErrorAction SilentlyContinue)
                {
                    $actionParams = @{}
                    $commandOptions = $DatumHandlers.$handler.CommandOptions.Keys

                    # Populate the Command's params with what's in the Datum.yml, or from variables
                    $variables = Get-Variable
                    foreach ($paramName in $actionCommand.Parameters.Keys)
                    {
                        if ($paramName -in $commandOptions)
                        {
                            $actionParams.Add($paramName, $DatumHandlers.$handler.CommandOptions[$paramName])
                        }
                        elseif ($var = $Variables.Where{ $_.Name -eq $paramName })
                        {
                            $actionParams."$paramName" = $var.Value
                        }
                    }
                    $result.Value = (&$actionCommand @actionParams)
                    if ($null -eq $result.Value)
                    {
                        $result.Value = [string]::Empty
                    }
                    return $true
                }
            }
            catch
            {
                Write-Warning "Error using Datum Handler $Handler, the error was: '$($_.Exception.Message)'. Returning InputObject ($InputObject)."
                $result = $InputObject
                return $false
            }
        }
    }

    return $return
}
