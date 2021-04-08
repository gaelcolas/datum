class Node : hashtable
{
    Node([hashtable]$NodeData)
    {
        $NodeData.Keys | ForEach-Object {
            $this[$_] = $NodeData[$_]
        }

        $this | Add-Member -MemberType ScriptProperty -Name Roles -Value {
            $pathArray = $ExecutionContext.InvokeCommand.InvokeScript('Get-PSCallStack')[2].Position.Text -split '\.'
            $propertyPath = $pathArray[2..($pathArray.Count - 1)] -join '\'
            Write-Warning -Message "Resolve $propertyPath"

            $obj = [PSCustomObject]@{}
            $currentNode = $obj
            if ($pathArray.Count -gt 3)
            {
                foreach ($property in $pathArray[2..($pathArray.count - 2)])
                {
                    Write-Debug -Message "Adding $Property property"
                    $currentNode | Add-Member -MemberType NoteProperty -Name $property -Value ([PSCustomObject]@{})
                    $currentNode = $currentNode.$property
                }
            }
            Write-Debug -Message "Adding Resolved property to last object's property $($pathArray[-1])"
            $currentNode | Add-Member -MemberType NoteProperty -Name $pathArray[-1] -Value $propertyPath

            return $obj
        }
    }
    static ResolveDscProperty($Path)
    {
        "Resolve-DscProperty $Path"
    }
}
