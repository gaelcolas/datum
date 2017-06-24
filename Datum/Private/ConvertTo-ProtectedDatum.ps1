function ConvertTo-ProtectedDatum
{###########ConvertTo-DatumSecureObjectReader
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
       [SecureDatum]::GetObject($InputObject)
    }
}