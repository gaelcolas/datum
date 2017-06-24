Class SecureDatum {
    [hashtable] hidden  $UnprotectParams
    SecureDatum($Object,[hashtable]$UnprotectParams) {
        $this.UnprotectParams = $UnprotectParams
        if($Object -is [hashtable]) {
            $Object = [PSCustomObject]$Object
        }

        if ($Object -is [PSCustomObject]) {
            foreach ($Property in $Object.PSObject.Properties.name) {
                $MemberTypeParams = @{
                    MemberType = 'NoteProperty'
                    Name = $Property
                    Value = ([SecureDatum]::GetObject($Object.$Property,$UnprotectParams))
                }
                if ($MemberTypeParams.Value -is [scriptblock]) {
                    $MemberTypeParams.MemberType = 'ScriptProperty'
                }
                $This | Add-Member @MemberTypeParams
            }
        }
    }
    [string] ToString()
    {
        return "{$($this.PSObject.Properties.Name -join ', ')}"
    }
    static [object] GetObject($object,$UnprotectParams)
    {
        if($null -eq $object) {
            return $null
        }
        elseif($object -is [PSCustomObject] -or
            $object -is [hashtable]) {
            return ([SecureDatum]::new($object,$UnprotectParams))
        }
        elseif ($object -is [System.Collections.IEnumerable] -and $object -isnot [string]) {
            $collection = @()
            $collection = foreach ($item in $object) {
                [SecureDatum]::GetObject($item,$UnprotectParams)
            }
            return $collection
        }
        elseif($object -is [string] -and $object -match "^\[ENC=[\w\W]*\]$") {
            $UnprotectScriptBlock = "
                `$Base64Data = `"$object`"
                `[SecureDatum]::Unprotect(`$Base64Data.Trim(),`$this.UnprotectParams)
                "
            return ([scriptblock]::Create($UnprotectScriptBlock))
        }
        else {
            return $object
        }
    }
    static [object] Unprotect($object,$UnprotectParams)
    {
        return (Unprotect-Datum -Base64Data $object @UnprotectParams)
    }
}
