#Requires -Modules Pester
Param (
    [io.DirectoryInfo]
    $ProjectPath = (property ProjectPath (Join-Path $PSScriptRoot '../..' -Resolve -ErrorAction SilentlyContinue)),

    [string]
    $BuildOutput = (property BuildOutput 'C:\BuildOutput'),

    [bool]
    $TestFromBuildOutput = $true,

    [string]
    $ProjectName = (property ProjectName (Split-Path -Leaf (Join-Path $PSScriptRoot '../..')) ),

    [string]
    $PesterOutputFormat = (property PesterOutputFormat 'NUnitXml'),

    [string]
    $PesterOutputSubFolder = (property PesterOutputSubFolder 'PesterOut'),

    [string]
    $RelativePathToIntegrationTests = (property RelativePathToIntegrationTests 'tests/Integration'),

    [string]
    $LineSeparation = (property LineSeparation ('-' * 78))
)
task IntegrationTests {
    $LineSeparation
    "`t`t`t RUNNING INTEGRATION TESTS"
    $LineSeparation
    "`tProject Path = $ProjectPath"
    "`tProject Name = $ProjectName"
    "`tIntegration Tests   = $RelativePathToIntegrationTests"
    $IntegrationTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$ProjectName,$RelativePathToIntegrationTests)
     "`tIntegration Tests  = $IntegrationTestPath"

    if (!$IntegrationTestPath.Exists -and
        (   #Try a module structure where the
            ($IntegrationTestPath = [io.DirectoryInfo][system.io.path]::Combine($ProjectPath,$RelativePathToIntegrationTests)) -and
            !$IntegrationTestPath.Exists
        )
    )
    {
        Write-Warning ('Integration tests Path Not found {0}' -f $IntegrationTestPath)
        return
    }
    
    "`tIntegrationTest Path: $IntegrationTestPath"
    ''
    Import-module Pester -ErrorAction Stop
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $ProjectPath.FullName -ChildPath $BuildOutput
    }

    $PSVersion = 'PSv{0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $TestResultFileName = "Integration_$PSVersion`_$TimeStamp.xml"
    $TestResultFile = [system.io.path]::Combine($BuildOutput,'testResults','Integration',$PesterOutputFormat,$TestResultFileName)
    $TestResultFileParentFolder = Split-Path $TestResultFile -Parent
    $PesterOutFilePath = [system.io.path]::Combine($BuildOutput,'testResults','Integration',$PesterOutputSubFolder,$TestResultFileName)
    $PesterOutParentFolder = Split-Path $PesterOutFilePath -Parent

     
    if (!(Test-Path $PesterOutParentFolder)) {
        Write-Verbose "CREATING Pester Results Output Folder $PesterOutParentFolder"
        $null = mkdir $PesterOutParentFolder -Force
    }

    if (!(Test-Path $TestResultFileParentFolder)) {
        Write-Verbose "CREATING Test Results Output Folder $TestResultFileParentFolder"
        $null = mkdir $TestResultFileParentFolder -Force
    }
    
    Push-Location $IntegrationTestPath
    
    if($TestFromBuildOutput) {
        Import-Module -Force ("$BuildOutput\$ProjectName" -replace '\\$')
    }
    else {
        Import-Module -Force ("$ProjectPath\$ProjectName" -replace '\\$')
    }
    $PesterParams = @{
        ErrorAction  = 'Stop'
        OutputFormat = $PesterOutputFormat
        OutputFile   = $TestResultFile
        PassThru     = $true
    }
    Import-module Pester -ErrorAction Stop
    if($TestFromBuildOutput) {
        Import-Module -Force ("$BuildOutput\$ProjectName" -replace '\\$')
    }
    else {
        Import-Module -Force ("$ProjectPath\$ProjectName" -replace '\\$')
    }

    $script:IntegrationTestResults = Invoke-Pester @PesterParams
    $null = $script:IntegrationTestResults | Export-Clixml -Path $PesterOutFilePath -Force
    Pop-Location

    Pop-Location
   
}


task FailBuildIfFailedIntegrationTest -If ($CodeCoverageThreshold -ne 0) {
    assert ($script:IntegrationTestResults.FailedCount -eq 0) ('Failed {0} Integration tests. Aborting Build' -f $script:IntegrationTestResults.FailedCount)
}