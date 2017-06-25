Class Node {
    Node()
    {
        $this | Add-member -MemberType ScriptProperty -Name HERE -Value {
            
            $PathArray = (Get-PSCallStack)[1].Position.text -split '\.'
            $PropertyPath =  $PathArray[1..($PathArray.count-1)] -join '\'
            
            write-host "Resolve-DscProperty '$PropertyPath'"
        }
    }
}

$node = [Node]::new()
$node.HERE.There.is.nothing.here.anyway

$node = @{
    Roles = @{
        Web = @{
            Property1 = [Node]::new()

            Property2 = [Node]::new()
        }

        PullSrv = @{
            Prop = [Node]::new()
        }
    }
}
