#Requires -Modules ProtectedData

function Protect-Datum {
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
        [PSObject]
        $InputObject,
        
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
        [Int]
        $MaxLineLength = 100,

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
    
    begin {
    }
    
    process {
        Write-Verbose "Deserializing the Object from Base64"
        
        $ProtectDataParams = @{
            InputObject = $InputObject
        }
        Write-verbose "Calling Protect-Data $($PSCmdlet.ParameterSetName)"
        Switch ($PSCmdlet.ParameterSetName) {
            'ByCertificate' { $ProtectDataParams.Add('Certificate',$Certificate)}
            'ByPassword'    { $ProtectDataParams.Add('Password',$Password)      }
        }

        $securedData =  Protect-Data @ProtectDataParams
        $xml = [System.Management.Automation.PSSerializer]::Serialize($securedData, 5)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($xml)
        $Base64String = [System.Convert]::ToBase64String($bytes)
        
        if($MaxLineLength -gt 0) {
            $Base64DataBlock = [regex]::Replace($Base64String,"(.{$MaxLineLength})","`$1`r`n")
        }
        else {
            $Base64DataBlock = $Base64String
        }
        if(!$NoEncapsulation) {
            $Header,$Base64DataBlock,$Footer -join ''
        }
        else {
            $Base64DataBlock
        }
    }
}