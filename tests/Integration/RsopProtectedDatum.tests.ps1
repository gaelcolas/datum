using module datum

$here = $PSScriptRoot

$global:ErrorActionPreference = 'Stop' #This is the default in Azure pipelines, but not in local tests
Remove-Module -Name datum

BeforeDiscovery {
    Import-Module -Name datum

    $datumPath = Join-Path -Path $here -ChildPath '.\assets\DscWorkshopConfigData\Datum.yml' -Resolve
    Write-Host "Loading datum from '$datumPath'"
    $script:datum = New-DatumStructure -DefinitionFile $datumPath

    $script:allNodes = $datum.AllNodes.Dev.psobject.Properties | ForEach-Object {
        $node = $datum.AllNodes.Dev.($_.Name)
        (@{} + $node)
    }

    $global:configurationData = @{
        AllNodes = $script:allNodes
        Datum    = $script:datum
    }

    # Set build output path with fallback for direct Pester runs
    $buildOutput = if ($BuildModuleOutput) { $BuildModuleOutput } else { "$here\..\..\output" }
    $script:rsopPath = Join-Path -Path $buildOutput -ChildPath RSOP
    $script:rsopWithSourcePath = Join-Path -Path $buildOutput -ChildPath RsopWithSource
    mkdir -Path $rsopPath, $rsopWithSourcePath -Force | Out-Null
}

Describe "Datum Handler tests based on 'DscWorkshopConfigData' test data" {

    BeforeAll {
        # Reload module for test execution
        if (Get-Module -Name datum -ErrorAction SilentlyContinue) {
            Remove-Module -Name datum -Force
        }
        Import-Module -Name datum -Force

        $datumPath = Join-Path -Path $PSScriptRoot -ChildPath '.\assets\DscWorkshopConfigData\Datum.yml' -Resolve
        $script:datum = New-DatumStructure -DefinitionFile $datumPath

        $script:allNodes = $script:datum.AllNodes.Dev.psobject.Properties | ForEach-Object {
            $node = $script:datum.AllNodes.Dev.($_.Name)
            (@{} + $Node)
        }

        $global:configurationData = @{
            AllNodes = $script:allNodes
            Datum    = $script:datum
        }

        # Set build output path with fallback for direct Pester runs
        $buildOutput = if ($BuildModuleOutput) { $BuildModuleOutput } else { "$PSScriptRoot\..\..\output" }
        $script:rsopPath = Join-Path -Path $buildOutput -ChildPath RSOP
        $script:rsopWithSourcePath = Join-Path -Path $buildOutput -ChildPath RsopWithSource
        mkdir -Path $script:rsopPath, $script:rsopWithSourcePath -Force | Out-Null
    }

    Context 'Accessing credentials with the correct key' {

        It "The property 'SomeWorkingCredential' is a 'PSCredential' object" {
            $node = $global:configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $script:datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $script:rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeWorkingCredential | Should -BeOfType [pscredential]
        }

        It "The username in 'SomeWorkingCredential' is 'contoso\install'" {
            $node = $global:configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $script:datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $script:rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeWorkingCredential.UserName | Should -Be 'contoso\install'
        }

        foreach ($node in $global:configurationData.AllNodes) {
            $script:rsop = Get-DatumRsop -Datum $script:datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $script:rsopWithSourcePath -ChildPath "$($node.NodeName).yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            It "The domain join credentials for node '$($node.NodeName)' could be accessed" {

                $rsop.ComputerSettings.Credential | Should -BeOfType [pscredential]

            }
        }
    }

    Context 'Accessing credentials with the wrong key' {

        It "The property 'SomeNonWorkingCredential' is a string like '[ENC*]'" {
            $node = $global:configurationData.AllNodes | Where-Object NodeName -EQ DSCFile01

            $rsop = Get-DatumRsop -Datum $script:datum -AllNodes $node
            $nodeRsopPath = Join-Path -Path $script:rsopPath -ChildPath "$node.yml" -ErrorAction Stop
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsop.SomeNonWorkingCredential | Should -Belike '`[ENC=*'
        }
    }
}
