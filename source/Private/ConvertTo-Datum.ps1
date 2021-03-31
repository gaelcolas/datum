function ConvertTo-Datum
{
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]
        $InputObject,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHandlers = @{}
    )

    begin
    {
        $handlerNames = $DatumHandlers.Keys
    }

    process
    {
        if ($null -eq $InputObject)
        {
            return $null
        }

        if ($InputObject -is [System.Collections.IDictionary])
        {
            $hashKeys = [string[]]$InputObject.Keys
            foreach ($key in $hashKeys)
            {
                $InputObject[$key] = ConvertTo-Datum -InputObject $InputObject[$key] -DatumHandlers $DatumHandlers
            }
            # Making the Ordered Dict Case Insensitive
            ([ordered]@{} + $InputObject)
        }
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject)
                {
                    ConvertTo-Datum -InputObject $object -DatumHandlers $DatumHandlers
                }
            )

            , $collection
        }
        elseif (($InputObject -is [psobject] -or $InputObject -is [DatumProvider]) -and $InputObject -isnot [pscredential])
        {
            $hash = [ordered]@{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertTo-Datum -InputObject $property.Value -DatumHandlers $DatumHandlers
            }

            $hash
        }
        # if There's a matching filter, process associated command and return result
        elseif ($handlerNames -and ($result = & {
                    foreach ($handler in $handlerNames)
                    {
                        $filterModule, $filterName = $handler -split '::'
                        if (-not (Get-Module -Name $filterModule))
                        {
                            Import-Module -Name $filterModule -Force -ErrorAction Stop
                        }
                        $filterCommand = Get-Command -Name ('{0}\Test-{1}Filter' -f $filterModule, $filterName) -ErrorAction SilentlyContinue
                        if ($filterCommand -and ($InputObject | &$filterCommand))
                        {
                            try
                            {
                                if ($actionCommand = Get-Command -Name ('{0}\Invoke-{1}Action' -f $filterModule, $filterName) -ErrorAction SilentlyContinue)
                                {
                                    $actionParams = @{}
                                    $commandOptions = $Datumhandlers.$handler.CommandOptions.Keys
                                    # Populate the Command's params with what's in the Datum.yml, or from variables
                                    $variables = Get-Variable
                                    foreach ($paramName in $actionCommand.Parameters.Keys )
                                    {
                                        if ($paramName -in $commandOptions)
                                        {
                                            $actionParams.Add($paramName, $Datumhandlers.$handler.CommandOptions[$paramName])
                                        }
                                        elseif ($var = $variables.Where{ $_.Name -eq $paramName })
                                        {
                                            $actionParams.Add($paramName, $var.Value)
                                        }
                                    }
                                    $result = &$actionCommand @ActionParams
                                    $result
                                }
                            }
                            catch
                            {
                                Write-Warning "Error using Datum Handler $handler, returning Input Object. The error was: '$($_.Exception.Message)'."
                                $InputObject
                            }
                        }
                    }
                }))
        {
            $result
        }
        else
        {
            $InputObject
        }
    }
}
