using module datum

Remove-Module -Name datum

Describe "RSOP tests based on 'MergeTestData' test data" {
    BeforeAll {
        $here = $PSScriptRoot
        Import-Module -Name datum

        # $here is set at file scope and should be available here
        # Path should be: tests\Integration\assets\MergeTestData\Datum.yml
        $datumPath = Join-Path -Path $here -ChildPath 'assets\MergeTestData\Datum.yml'
        if (-not (Test-Path $datumPath)) {
            throw "Cannot find Datum.yml at: $datumPath (here = $here)"
        }

        $datum = New-DatumStructure -DefinitionFile $datumPath
        $allNodes = $datum.AllNodes.psobject.Properties | ForEach-Object {
            $node = $Datum.AllNodes.($_.Name)
            (@{} + $Node)
        }

        $global:configurationData = @{
            AllNodes = $allNodes
            Datum    = $datum
        }

        if (-not $BuildModuleOutput) {
            $BuildModuleOutput = "$here\..\..\output"
        }

        $rsopPath = Join-Path -Path $BuildModuleOutput -ChildPath RSOP
        $rsopWithSourcePath = Join-Path -Path $BuildModuleOutput -ChildPath RsopWithSource
        mkdir -Path $rsopPath, $rsopWithSourcePath -Force | Out-Null
    }

    Context 'Base-Type array merge behavior' {

        $script:testCases = @(
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'Configurations'
                Value        = 'FilesAndFolders', 'LocalUsers', 'NetworkIpConfigurationMerged', 'RegistryValues', 'SecurityOptions', 'SummaryConfig', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'Configurations'
                Value        = 'LocalUsers', 'NetworkIpConfigurationMerged', 'RegistryValues', 'SecurityOptions', 'SummaryConfig', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'Configurations'
                Value        = 'FilesAndFolders', 'LocalUsers', 'NetworkIpConfigurationMerged', 'RegistryValues', 'SecurityOptions', 'SummaryConfig', 'WindowsFeatures'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Destination'
                Value        = '192.168.11.0/24', '192.168.22.0/24', '192.168.33.0/24', '192.168.10.0/24', '192.168.20.0/24', '192.168.30.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Destination'
                Value        = '192.168.12.0/24', '192.168.23.0/24', '192.168.34.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Destination'
                Value        = '192.168.12.0/24', '192.168.23.0/24', '192.168.34.0/24', '192.168.10.0/24', '192.168.20.0/24', '192.168.30.0/24', '192.168.40.0/24', '192.168.50.0/24', '192.168.60.0/24'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'WindowsFeatures.Name'
                Value        = '-Telnet-Client', 'File-Services'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'WindowsFeatures.Name'
                Value        = 'File-Services', '-Telnet-Client', 'Telnet-Server'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'WindowsFeatures.Name'
                Value        = 'File-Services', 'Web-Server', 'XPS-Viewer', '-Telnet-Client'
            }
        )

        It "The value of Datum RSOP property '<PropertyPath>' for node '<Node>' should be '<Value>'." -ForEach $script:testCases {
            param ($Node, $PropertyPath, $Value)

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes -Filter { $_.NodeName -eq $Node }
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsopWithSource = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes -Filter { $_.NodeName -eq $Node } -IncludeSource
            $nodeRsopWithSourcePath = Join-Path -Path $rsopWithSourcePath -ChildPath "$node.yml"
            $rsopWithSource | ConvertTo-Yaml | Out-File -FilePath $nodeRsopWithSourcePath

            $cmd = [scriptblock]::Create("`$rsop.$PropertyPath")
            & $cmd | Sort-Object | Should -Be ($Value | Sort-Object)
        }
    }

    Context 'Hashtable array merge behavior' {

        $script:testCases = @(
            # DSCFile01 - Ethernet 1
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.IpAddress'
                Value        = '192.168.10.100'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                Value        = '192.168.10.50'
            }
            # DSCFile01 - Ethernet 2
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 2"}.IpAddress'
                Value        = '192.168.20.100'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 2"}.Gateway'
                Value        = '192.168.20.50'
            }
            # DSCFile01 - Ethernet 3
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 3"}.IpAddress'
                Value        = '192.168.30.100'
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 3"}.Gateway'
                Value        = $null
            }
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 3"}.DnsServer'
                Value        = '192.168.30.20'
            }
            # DSCFile01 - Interface count
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Count'
                Value        = 4
            }
            # DSCFile01 - LocalUsers - LocalAdmin
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'LocalUsers.Users.Where{$_.UserName -eq "LocalAdmin"}.Ensure'
                Value        = 'Present'
            }
            # DSCFile01 - LocalUsers - Admin1
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'LocalUsers.Users.Where{$_.UserName -eq "Admin1"}.Ensure'
                Value        = $null
            }
            # DSCFile01 - LocalUsers count
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'LocalUsers.Users.Count'
                Value        = 1
            }
            # DSCFile01 - LocalUsers UserName's
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'LocalUsers.Users.UserName'
                Value        = 'LocalAdmin'
            }
            # DSCFile01 - RegistryValues - DevicesPickerUserSvc - Start
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'RegistryValues.Values.Where{$_.Key -eq "HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc" -and $_.ValueName -eq "Start"}.Ensure'
                Value        = $null
            }
            # DSCFile01 - RegistryValues - DevicesPickerUserSvc - UserServiceFlags
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'RegistryValues.Values.Where{$_.Key -eq "HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc" -and $_.ValueName -eq "UserServiceFlags"}.Ensure'
                Value        = 'Present'
            }
            # DSCFile01 - RegistryValues count
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'RegistryValues.Values.Count'
                Value        = 3
            }
            # DSCFile01 - RegistryValues UserName's
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'RegistryValues.Values.Key'
                Value        = 'HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc', 'HKLM:\SYSTEM\CurrentControlSet\Services\CaptureService', 'HKLM:\SYSTEM\CurrentControlSet\Services\CaptureService'
            }
            # DSCFile01 - RegistryValues UserName's
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'RegistryValues.Values.ValueName'
                Value        = 'UserServiceFlags', 'Start', 'UserServiceFlags'
            }
            # DSCFile01 - Accounts_Rename_administrator_account
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'SecurityOptions.Policies.Where{$_.Name -eq "Accounts_Rename_administrator_account"}.Accounts_Rename_administrator_account'
                Value        = 'LocalAdmin'
            }
            # DSCFile01 - SummaryConfig count
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'SummaryConfig.SumItems.Count'
                Value        = 3
            }
            # DSCFile01 - SummaryConfig ItemNumbers
            @{
                Node         = 'DSCFile01'
                PropertyPath = 'SummaryConfig.SumItems.ItemNumber'
                Value        = 1, 2, 3
            }
            # DSCWeb01 - Ethernet 1
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.IpAddress'
                Value        = '192.168.10.101'
            }
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                Value        = $null
            }
            # DSCWeb01 - Interface count
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Count'
                Value        = 2
            }
            # DSCWeb01 - Ethernet 2
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 2"}'
                Value        = $null
            }
            # DSCWeb01 - LocalUsers - LocalAdmin
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'LocalUsers.Users.Where{$_.UserName -eq "LocalAdmin"}.Ensure'
                Value        = $null
            }
            # DSCWeb01 - LocalUsers - Admin1
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'LocalUsers.Users.Where{$_.UserName -eq "Admin1"}.Ensure'
                Value        = $null
            }
            # DSCWeb01 - LocalUsers count
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'LocalUsers.Users.Count'
                Value        = 0
            }
            # DSCWeb01 - LocalUsers UserName's
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'LocalUsers.Users.UserName'
                Value        = $null
            }
            # DSCWeb01 - RegistryValues - DevicesPickerUserSvc - Start
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'RegistryValues.Values.Where{$_.Key -eq "HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc" -and $_.ValueName -eq "Start"}.Ensure'
                Value        = $null
            }
            # DSCWeb01 - RegistryValues - DevicesPickerUserSvc - UserServiceFlags
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'RegistryValues.Values.Where{$_.Key -eq "HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc" -and $_.ValueName -eq "UserServiceFlags"}.Ensure'
                Value        = $null
            }
            # DSCWeb01 - RegistryValues count
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'RegistryValues.Values.Count'
                Value        = 2
            }
            # DSCWeb01 - RegistryValues UserName's
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'RegistryValues.Values.Key'
                Value        = 'HKLM:\SYSTEM\CurrentControlSet\Services\CaptureService', 'HKLM:\SYSTEM\CurrentControlSet\Services\CaptureService'
            }
            # DSCWeb01 - RegistryValues UserName's
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'RegistryValues.Values.ValueName'
                Value        = 'Start', 'UserServiceFlags'
            }
            # DSCWeb01 - Accounts_Rename_administrator_account
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'SecurityOptions.Policies.Where{$_.Name -eq "Accounts_Rename_administrator_account"}.Accounts_Rename_administrator_account'
                Value        = $null
            }
            # DSCWeb01 - SummaryConfig count
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'SummaryConfig.SumItems.Count'
                Value        = 3
            }
            # DSCWeb01 - SummaryConfig ItemNumbers
            @{
                Node         = 'DSCWeb01'
                PropertyPath = 'SummaryConfig.SumItems.ItemNumber'
                Value        = 1, 2, 4
            }
            # DSCWeb02 - Ethernet 1
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.IpAddress'
                Value        = '192.168.10.102'
            }
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 1"}.Gateway'
                Value        = '192.168.10.50'
            }
            # DSCWeb02 - Interface count
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Count'
                Value        = 2
            }
            # DSCWeb02 - Ethernet 2
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'NetworkIpConfigurationMerged.Interfaces.Where{$_.InterfaceAlias -eq "Ethernet 2"}'
                Value        = $null
            }
            # DSCWeb02 - LocalUsers - LocalAdmin
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'LocalUsers.Users.Where{$_.UserName -eq "LocalAdmin"}.Ensure'
                Value        = 'Absent'
            }
            # DSCWeb02 - LocalUsers - Admin1
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'LocalUsers.Users.Where{$_.UserName -eq "Admin1"}.Ensure'
                Value        = 'Present'
            }
            # DSCWeb02 - LocalUsers count
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'LocalUsers.Users.Count'
                Value        = 2
            }
            # DSCWeb02 - LocalUsers UserName's
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'LocalUsers.Users.UserName'
                Value        = 'LocalAdmin', 'Admin1'
            }
            # DSCWeb02 - RegistryValues - DevicesPickerUserSvc - Start
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'RegistryValues.Values.Where{$_.Key -eq "HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc" -and $_.ValueName -eq "Start"}.Ensure'
                Value        = 'Absent'
            }
            # DSCWeb02 - RegistryValues - DevicesPickerUserSvc - UserServiceFlags
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'RegistryValues.Values.Where{$_.Key -eq "HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc" -and $_.ValueName -eq "UserServiceFlags"}.Ensure'
                Value        =  $null
            }
            # DSCWeb02 - RegistryValues count
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'RegistryValues.Values.Count'
                Value        = 3
            }
            # DSCWeb02 - RegistryValues UserName's
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'RegistryValues.Values.Key'
                Value        = 'HKLM:\SYSTEM\CurrentControlSet\Services\DevicesPickerUserSvc', 'HKLM:\SYSTEM\CurrentControlSet\Services\CaptureService', 'HKLM:\SYSTEM\CurrentControlSet\Services\CaptureService'
            }
            # DSCWeb02 - RegistryValues UserName's
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'RegistryValues.Values.ValueName'
                Value        = 'Start', 'Start', 'UserServiceFlags'
            }
            # DSCWeb02 - Accounts_Rename_administrator_account
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'SecurityOptions.Policies.Where{$_.Name -eq "Accounts_Rename_administrator_account"}.Accounts_Rename_administrator_account'
                Value        = 'Admin1'
            }
            # DSCWeb02 - SummaryConfig count
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'SummaryConfig.SumItems.Count'
                Value        = 2
            }
            # DSCWeb02 - SummaryConfig ItemNumbers
            @{
                Node         = 'DSCWeb02'
                PropertyPath = 'SummaryConfig.SumItems.ItemNumber'
                Value        = 1, 2
            }
        )

        It "The value of Datum RSOP property '<PropertyPath>' for node '<Node>' should be '<Value>'." -ForEach $script:testCases {
            param ($Node, $PropertyPath, $Value)

            $rsop = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes -Filter { $_.NodeName -eq $Node }
            $nodeRsopPath = Join-Path -Path $rsopPath -ChildPath "$node.yml"
            $rsop | ConvertTo-Yaml | Out-File -FilePath $nodeRsopPath

            $rsopWithSource = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes -Filter { $_.NodeName -eq $Node } -IncludeSource
            $nodeRsopWithSourcePath = Join-Path -Path $rsopWithSourcePath -ChildPath "$node.yml"
            $rsopWithSource | ConvertTo-Yaml | Out-File -FilePath $nodeRsopWithSourcePath

            $cmd = [scriptblock]::Create("`$rsop.$PropertyPath")
            & $cmd | Sort-Object | Should -Be ($Value | Sort-Object)
        }
    }

    Context 'Cache cmdlets' {

        BeforeAll {
            Clear-DatumRsopCache
        }

        It "'Clear-DatumRsopCache' returns `$null" {
            Get-DatumRsopCache | Should -Be $null
        }

        It "'Get-DatumRsopCache' returns the RSOP Cache" {
            $rsop = Get-DatumRsop -Datum $datum -AllNodes $configurationData.AllNodes
            $rsopCache = Get-DatumRsopCache

            $rsop.Count | Should -Be $rsopCache.Count
        }

    }
}
