function Invoke-DatumHandler
{
    <#
    .SYNOPSIS
        Invokes the configured datum handlers.

    .DESCRIPTION
        This function goes through all datum handlers configured in the 'datum.yml'. For all handlers, it calls the test function
        first that identifies if the particular handler should be invoked at all for the given InputString. The test function
        look for a prefix and suffix in orer to know if a handler should be called. For the handler 'Datum.InvokeCommand' the
        prefix is '[x=' and the siffix '=]'.

        Let's assume the handler is defined in a module named 'Datum.InvokeCommand'. The handler is introduced in the 'datum.yml'
        like this:

        DatumHandlers:
            Datum.InvokeCommand::InvokeCommand:
                SkipDuringLoad: true

        The name of the function that checks if the handler should be called is constructed like this:

            <FilterModuleName>\Test-<FilterName>Filter

        Considering the definition in the 'datum.yml', the actual function name will be:

            Datum.InvokeCommand\Test-InvokeCommandFilter

        Same rule applies for the action function that is actually the handler. Datum searches a function with the name

            <FilterModuleName>\Invoke-<FilterName>Action

        which will be in case of the filter module named 'Datum.InvokeCommand' and the filter name 'InvokeCommand':

            Datum.InvokeCommand\Invoke-InvokeCommandAction

    .EXAMPLE
        This sample calls the handlers defined in the 'Datum.yml' on the value  '[x= { Get-Date } =]'. Only a handler will
        be invoked that has the prefix '[x=' and the siffix '=]'.

        PS C:\> $d = New-DatumStructure -DefinitionFile .\tests\Integration\assets\DscWorkshopConfigData\Datum.yml
        PS C:\> $result = $nul
        PS C:\> Invoke-DatumHandler -InputObject '[x= { Get-Date } =]' -DatumHandlers $d.__Definition.DatumHandlers -Result ([ref]$result)
        PS C:\> $result #-> Thursday, March 24, 2022 1:54:51 AM

    .INPUTS
        [object]

    .OUTPUTS
        Whatever the datum handler returns.

    .NOTES

    #>

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

        $filterModule, $filterName = $handler -split '::'
        if (-not (Get-Module $filterModule))
        {
            Import-Module $filterModule -Force -ErrorAction Stop
        }

        $filterCommand = Get-Command -ErrorAction SilentlyContinue ('{0}\Test-{1}Filter' -f $filterModule, $filterName)
        if ($filterCommand -and ($InputObject | &$filterCommand))
        {
            try
            {
                if ($actionCommand = Get-Command -Name ('{0}\Invoke-{1}Action' -f $filterModule, $filterName) -ErrorAction SilentlyContinue)
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
                $throwOnError = [bool]$datum.__Definition.DatumHandlersThrowOnError

                if ($throwOnError)
                {
                    Write-Error -ErrorRecord $_ -ErrorAction Stop
                }
                else
                {
                    Write-Warning "Error using Datum Handler '$Handler', the error was: '$($_.Exception.Message)'. Returning InputObject ($InputObject)."
                    $Result = $InputObject
                    return $false
                }
            }
        }
    }

    return $return
}
