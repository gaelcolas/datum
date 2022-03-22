function Copy-Object
{
    <#
    .SYNOPSIS
        Creates a real copy of an object recursive including all the referenced objects it points to.

    .DESCRIPTION

        In .net reference types (classes), cannot be copied easily. If a type implements the IClonable interface it can be copied
        or cloned but the objects it references to will not be cloned. Rather the reference is cloned like shown in this example:

        $a = @{
            k1 = 'v1'
            k2 = @{
                kk1 = 'vv1'
                kk2 = 'vv2'
            }
        }

        $b = @{}
        $validKeys = 'k1', 'k2'
        foreach ($validKey in $validKeys)
        {
            if ($a.ContainsKey($validKey))
            {
                $b.Add($validKey, $a.Item($validKey))
            }
        }

        Write-Host '-------- Before removal of kk2 -------------'
        Write-Host "Key count of a.k2: $($a.k2.Keys.Count)"
        Write-Host "Key count in b.k2: $($b.k2.Keys.Count)"

        $b.k2.Remove('kk2')
        Write-Host '-------- After removal of kk2 --------------'
        Write-Host "Key count of a.k2: $($a.k2.Keys.Count)"
        Write-Host "Key count in b.k2: $($b.k2.Keys.Count)"


    .EXAMPLE
        PS C:\> $clonedObject = Copy-Object -DeepCopyObject $someObject

    .INPUTS
        [object]

    .OUTPUTS
        [object]

    #>

    param (
        [Parameter(Mandatory = $true)]
        [object]
        $DeepCopyObject
    )

    $serialData = [System.Management.Automation.PSSerializer]::Serialize($DeepCopyObject)
    [System.Management.Automation.PSSerializer]::Deserialize($serialData)
}
