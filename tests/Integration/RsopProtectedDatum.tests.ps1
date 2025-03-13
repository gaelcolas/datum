using module datum

$here = $PSScriptRoot

Remove-Module -Name datum

Describe "Datum Handler tests based on 'DscWorkshopConfigData' test data" {
    BeforeAll {
        Import-Module -Name datum

        $datumPath = Join-Path -Path $here -ChildPath '.\assets\DscWorkshopConfigData\Datum.yml' -Resolve
        Write-Host "Loading datum from '$datumPath'"
        $datum = New-DatumStructure -DefinitionFile $datumPath

        Write-Host -------------------------------------
        $datum.__Definition | ConvertTo-Json -Depth 6 | Write-Host -ForegroundColor Green
        Write-Host -------------------------------------

        $allNodes = $datum.AllNodes.Dev.psobject.Properties | ForEach-Object {
            $node = $Datum.AllNodes.Dev.($_.Name)
            (@{} + $Node)
        }

        $global:configurationData = @{
            AllNodes = $allNodes
            Datum    = $datum
        }

        $rsopPath = Join-Path -Path $BuildModuleOutput -ChildPath RSOP
        $rsopWithSourcePath = Join-Path -Path $BuildModuleOutput -ChildPath RsopWithSource
        mkdir -Path $rsopPath, $rsopWithSourcePath -Force | Out-Null
    }

    Context 'Accessing credentials with the correct key' {

        It "The property 'SomeWorkingCredential' is a 'PSCredential' object" {
            $node = $configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeWorkingCredential | Should -BeOfType [pscredential]
        }

        It "The username in 'SomeWorkingCredential' is 'contoso\install'" {
            $node = $configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeWorkingCredential.UserName | Should -Be 'contoso\install'
        }

        foreach ($node in $configurationData.AllNodes) {
            $rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopWithSourcePath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            It "The domain join credentials for node '$($node.NodeName)' could be accessed" {

                $rsop.ComputerSettings.Credential | Should -BeOfType [pscredential]

            }
        }
    }

    Context 'Accessing credentials with the wrong key' {

        It "The property 'SomeWorkingCredential' is a 'PSCredential' object" {
            $node = $configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeNonWorkingCredential | Should -BeNullOrEmpty
        }
    }
}
