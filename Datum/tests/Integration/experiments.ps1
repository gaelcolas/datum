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

Lookup Configurations

Lookup MergeTest1