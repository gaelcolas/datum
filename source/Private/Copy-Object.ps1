function Copy-Object
{
    param (
        [Parameter(Mandatory)]
        [object]
        $DeepCopyObject
    )

    $serialData = [System.Management.Automation.PSSerializer]::Serialize($DeepCopyObject)
    [System.Management.Automation.PSSerializer]::Deserialize($serialData)
}
