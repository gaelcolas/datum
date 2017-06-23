#Requires -Modules ProtectedData

function Unprotect-Datum {
    [CmdletBinding()]
    [OutputType([PSObject])]
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
        $Base64Data,
        
        # By Password only for development / Test purposes
        [Parameter(
            ParameterSetName='ByPassword'
            ,Mandatory
            ,Position=1
            ,ValueFromPipelineByPropertyName
        )]
        [System.Security.SecureString]
        $Password,
        
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
        $Encapsulated
    )
    
    begin {
    }
    
    process {
        if ($Encapsulated) {
            $Base64Data = $Base64Data -replace "^$([regex]::Escape($Header))" -replace "$([regex]::Escape($Footer))$"
        }
        Write-Verbose "Removing $header DATA $footer "
        
        Write-Verbose "Deserializing the Object from Base64"
        $bytes = [System.Convert]::FromBase64String($Base64Data)
        $xml = [System.Text.Encoding]::UTF8.GetString($bytes)
        $obj = [System.Management.Automation.PSSerializer]::Deserialize($xml)
        $UnprotectDataParams = @{
            InputObject = $obj
        }
        Write-verbose "Calling Unprotect-Data $($PSCmdlet.ParameterSetName)"
        Switch ($PSCmdlet.ParameterSetName) {
            'ByCertificae' { $UnprotectDataParams.Add('Certificate',$Certificate)}
            'ByPassword'   { $UnprotectDataParams.Add('Password',$Password)      }
        }
        Unprotect-Data @UnprotectDataParams
    }

}