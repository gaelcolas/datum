if ($PSScriptRoot) {
    $here = $PSScriptRoot
}
else {
    $here = Join-Path $pwd.Path '*\tests\Integration\' -Resolve
}

$Datum = New-Datumstructure -DefinitionFile  (Join-path $here '.\assets\DSC_ConfigData\Datum.yml' -Resolve) 
$Environment = 'DEV'
$AllNodes = @($Datum.AllNodes.($Environment).psobject.Properties | ForEach-Object { 
    $Node = $Datum.AllNodes.($Environment).($_.Name)
    $null = $Node.Add('Environment',$Environment)
    if(!$Node.contains('Name') ) {
        $null = $Node.Add('Name',$_.Name)
    }
    (@{} + $Node)
})

$ConfigurationData = @{
    AllNodes = $AllNodes
    Datum = $Datum
}
$Node = $ConfigurationData.AllNodes[2]

$TestCases = @(
    @{PropertyPath = 'ExampleProperty1'; ExpectedResult = 'From Node'}
    @{PropertyPath = 'Description';      ExpectedResult = 'This is the DEV environment' }
    @{PropertyPath = 'Shared1\Param1';   ExpectedResult = 'This is the Role override!'}
    @{PropertyPath = 'locationName';     ExpectedResult = 'London'}
    
)

Write-Warning "Lookup <Configurations> for $($Node.Name)"
Lookup Configurations

Write-Warning "Lookup <MergeTest1> for $($Node.Name)"
Lookup MergeTest1

Write-Warning "Lookup <Configurations> -Node 'SRV02"
Lookup MergeTest1 -Node 'SRV02'

Write-Warning "Lookup MergeTest1 for $($Node.Name)"
$a = (lookup MergeTest1)

Write-Warning "Show MergeTest1.MergeStringArray merging result:"
$a.MergeStringArray

Write-Warning "Show MergeTest1.MergeHashArrays merging result:"
$a.MergeHashArrays|% {$_; "`r`n"}; 