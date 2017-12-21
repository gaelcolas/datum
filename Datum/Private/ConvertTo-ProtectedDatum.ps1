function ConvertTo-ProtectedDatum
{###########ConvertTo-DatumSecureObjectReader
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject,

        $UnprotectOptions
    )

    process
    {
        if ($UnprotectOptions.contains('ClearTextPassword')) {
            $UnprotectOptions['password'] = $UnprotectOptions.ClearTextPassword |
                ConvertTo-SecureString -AsPlainText -force
            $null = $UnprotectOptions.remove('ClearTextPassword')
        }
        elseif ($UnprotectOptions.contains('SecureStringPassword')) {
            $UnprotectOptions['password'] = $UnprotectOptions.SecureStringPassword |
                ConvertTo-SecureString
            $null = $UnprotectOptions.remove('SecureStringPassword')
        }
       [SecureDatum]::GetObject($InputObject,$UnprotectOptions)
    }
}