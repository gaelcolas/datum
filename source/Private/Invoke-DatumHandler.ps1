function Invoke-DatumHandler
{
    param (
        [Parameter(Mandatory = $true)]
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
                            $actionParams."$paramName" = $var[0].Value
                        }
                    }
                    $internalResult = (&$actionCommand @actionParams)
                    if ($null -eq $internalResult)
                    {
                        $Result.Value = [string]::Empty
                    }

                    $Result.Value = $internalResult
                    return $true
                }
            }
            catch
            {
                $throwOnError = $true

                if (Get-Item -Path Env:\DatumHandlerThrowsOnError -ErrorAction SilentlyContinue)
                {
                    [void][bool]::TryParse($env:DatumHandlerThrowsOnError, [ref]$throwOnError)
                }

                if ($throwOnError)
                {
                    Write-Error -ErrorRecord $_ -ErrorAction Stop
                }
                else
                {
                    Write-Warning "Error using Datum Handler $Handler, the error was: '$($_.Exception.Message)'. Returning InputObject ($InputObject)."
                    $Result = $InputObject
                    return $false
                }
            }
        }
    }

    return $return
}
