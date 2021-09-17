function Expand-RsopHashtable
{
    param (
        [Parameter()]
        [object]
        $InputObject,

        [Parameter()]
        [switch]
        $IsArrayValue,

        [Parameter()]
        [int]
        $Depth,

        [Parameter()]
        [switch]
        $NoSourceInformation
    )

    $Depth++

    if ($null -eq $InputObject)
    {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary])
    {
        $newObject = @{}
        $keys = [string[]]$InputObject.Keys
        foreach ($key in $keys)
        {
            $newObject.$key = Expand-RsopHashtable -InputObject $InputObject[$key] -Depth $Depth -NoSourceInformation:$NoSourceInformation
        }

        [ordered]@{} + $newObject
    }
    elseif ($InputObject -is [System.Collections.IList])
    {
        $doesUseYamlArraySyntax = [bool]($InputObject.Count - 1)
        if (-not $doesUseYamlArraySyntax)
        {
            $depth--
        }
        $items = foreach ($item in $InputObject)
        {
            Expand-RsopHashtable -InputObject $item -IsArrayValue:$doesUseYamlArraySyntax -Depth $Depth -NoSourceInformation:$NoSourceInformation
        }
        $items
    }
    elseif ($InputObject -is [pscredential])
    {
        $cred = $InputObject.GetNetworkCredential()
        $cred = "$($cred.UserName)@$($cred.Domain)$(if($cred.Domain){':'})$($cred.Password)" | Add-Member -Name __File -MemberType NoteProperty -Value $InputObject.__File -PassThru

        Get-RsopValueString -InputString $cred -Key $key -Depth $depth -IsArrayValue:$IsArrayValue -NoSourceInformation:$NoSourceInformation
    }
    else
    {
        Get-RsopValueString -InputString $InputObject -Key $key -Depth $depth -IsArrayValue:$IsArrayValue -NoSourceInformation:$NoSourceInformation
    }
}
