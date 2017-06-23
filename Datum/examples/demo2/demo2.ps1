
$password = 'P@ss0rd' | ConvertTo-SecureString -AsPlainText -Force
$data = 'this is clear text data'

#Encrypt Data
$securedData = Protect-Data -InputObject $data -Password $password
$xml = [System.Management.Automation.PSSerializer]::Serialize($securedData, 5)
$bytes = [System.Text.Encoding]::UTF8.GetBytes($xml)
$base64 = [System.Convert]::ToBase64String($bytes)

$base64

#Decrypt Data
$bytes = [System.Convert]::FromBase64String($base64)
$xml = [System.Text.Encoding]::UTF8.GetString($bytes)
$obj = [System.Management.Automation.PSSerializer]::Deserialize($xml)
Unprotect-Data -InputObject $obj -Password $password

