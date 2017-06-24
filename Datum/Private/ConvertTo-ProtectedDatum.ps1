function ConvertTo-ProtectedDatum
{###########ConvertTo-DatumSecureObjectReader
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject,

        $UnprotectOptions
    )

    process
    {
        if ($UnprotectOptions.ContainsKey('ClearTextPassword')) {
            $UnprotectOptions['password'] = $UnprotectOptions.ClearTextPassword |
                ConvertTo-SecureString -AsPlainText -force
            $null = $UnprotectOptions.remove('ClearTextPassword')
        }
        elseif ($UnprotectOptions.ContainsKey('SecureStringPassword')) {
            $UnprotectOptions['password'] = $UnprotectOptions.SecureStringPassword |
                ConvertTo-SecureString
            $null = $UnprotectOptions.remove('SecureStringPassword')
        }
       [SecureDatum]::GetObject($InputObject,$UnprotectOptions)
    }
}