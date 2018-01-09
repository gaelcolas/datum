function Invoke-ProtectedDatumAction {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    Param (
        # Serialized Protected Data represented on Base64 encoding
        [Parameter(
             Mandatory
            ,Position=0
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $InputObject,
        
        # By Password only for development / Test purposes
        [Parameter(
            ParameterSetName='ByPassword'
            ,Mandatory
            ,Position=1
            ,ValueFromPipelineByPropertyName
        )]
        [String]
        $PlainTextPassword,
        
        # Specify the Certificate to be used by ProtectedData
        [Parameter(
            ParameterSetName='ByCertificate'
            ,Mandatory
            ,Position=1
            ,ValueFromPipelineByPropertyName
        )]
        [String]
        $Certificate,

        # Number of columns before inserting newline in chunk
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String]
        $Header = '[ENC=',

        # Number of columns before inserting newline in chunk
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String]
        $Footer = ']',

        # Number of columns before inserting newline in chunk
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoEncapsulation
    )
    Write-Debug "Decrypting Datum using ProtectedData"
    $params = @{}
    foreach($ParamKey in $PSBoundParameters.keys) {
        if($ParamKey -in @('InputObject','PlainTextPassword')) {
            switch ($ParamKey) {
                'PlainTextPassword' { $params.add('password',(ConvertTo-SecureString -AsPlainText -Force $PSBoundParameters[$ParamKey])) }
                'InputObject' { $params.add('Base64Data',$InputObject) }
            }
        }
        else {
            $params.add($ParamKey,$PSBoundParameters[$ParamKey])
        }
    }

    UnProtect-Datum @params

}