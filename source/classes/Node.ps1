Class Node : hashtable {
    Node([hashtable]$NodeData)
    {
        $NodeData.keys | % {
            $This[$_] = $NodeData[$_]
        }
        
        $this | Add-member -MemberType ScriptProperty -Name Roles -Value {
            $PathArray = $ExecutionContext.InvokeCommand.InvokeScript('Get-PSCallStack')[2].Position.text -split '\.'
            $PropertyPath =  $PathArray[2..($PathArray.count-1)] -join '\'
            Write-warning "Resolve $PropertyPath"
            
            $obj = [PSCustomObject]@{}
            $currentNode = $obj
            if($PathArray.Count -gt 3) {
                foreach ($property in $PathArray[2..($PathArray.count-2)]) {
                    Write-Debug "Adding $Property property"
                    $currentNode | Add-member -MemberType NoteProperty -Name $property -Value ([PSCustomObject]@{})
                    $currentNode = $currentNode.$property
                }    
            }
            Write-Debug "Adding Resolved property to last object's property $($PathArray[-1])"
            $currentNode | Add-member -MemberType NoteProperty -Name $PathArray[-1] -Value ($PropertyPath)

            return $obj
        }
    }
    static ResolveDscProperty($Path)
    {
        "Resolve-DscProperty $Path"
    }
}
 