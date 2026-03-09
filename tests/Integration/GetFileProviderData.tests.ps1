using module datum

Remove-Module -Name datum

Describe 'JSON and YAML file equivalence in Get-FileProviderData' {
    BeforeAll {
        $here = $PSScriptRoot
        Import-Module -Name datum

        $jsonDataPath = Join-Path -Path $here -ChildPath 'assets\JsonYamlEquivalence\JsonData'
        $yamlDataPath = Join-Path -Path $here -ChildPath 'assets\JsonYamlEquivalence\YamlData'

        $datumHandlers = @{
            'Datum::TestHandler' = @{
                CommandOptions = @{
                    Password = 'P@ssw0rd'
                    Test     = 'test'
                }
            }
        }
    }

    Context 'Simple data structures' {
        BeforeAll {
            $script:jsonResult = Get-FileProviderData -Path (Join-Path -Path $jsonDataPath -ChildPath 'SimpleData.json') -DatumHandlers $datumHandlers
            $script:yamlResult = Get-FileProviderData -Path (Join-Path -Path $yamlDataPath -ChildPath 'SimpleData.yml') -DatumHandlers $datumHandlers
        }

        It 'JSON result should be an OrderedDictionary' {
            $script:jsonResult | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'YAML result should be an OrderedDictionary' {
            $script:yamlResult | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'JSON and YAML should have the same top-level keys' {
            $jsonKeys = [string[]]$script:jsonResult.Keys
            $yamlKeys = [string[]]$script:yamlResult.Keys

            # Both are processed through ConvertTo-Datum and get __File added;
            # compare only the data keys.
            $jsonDataKeys = $jsonKeys | Where-Object { $_ -ne '__File' }
            $yamlDataKeys = $yamlKeys | Where-Object { $_ -ne '__File' }
            $jsonDataKeys | Should -Be $yamlDataKeys
        }

        It 'Simple string values should be identical' {
            $script:jsonResult.SimpleString | Should -Be $script:yamlResult.SimpleString
            $script:jsonResult.SimpleString | Should -Be 'hello'
        }

        It 'Simple integer values should be identical' {
            $script:jsonResult.SimpleInt | Should -Be $script:yamlResult.SimpleInt
            $script:jsonResult.SimpleInt | Should -Be 42
        }

        It 'Simple boolean values should be identical' {
            $script:jsonResult.SimpleBool | Should -Be $script:yamlResult.SimpleBool
            $script:jsonResult.SimpleBool | Should -Be $true
        }

        It 'Nested hashtable values should be identical' {
            $script:jsonResult.NestedHash.Key1 | Should -Be $script:yamlResult.NestedHash.Key1
            $script:jsonResult.NestedHash.Key2 | Should -Be $script:yamlResult.NestedHash.Key2
            $script:jsonResult.NestedHash.Key1 | Should -Be 'Value1'
        }

        It 'Nested hashtable should be an OrderedDictionary' {
            $script:jsonResult.NestedHash | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $script:yamlResult.NestedHash | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'Deeply nested values should be identical' {
            $script:jsonResult.NestedHash.DeeplyNested.Level3Key | Should -Be $script:yamlResult.NestedHash.DeeplyNested.Level3Key
            $script:jsonResult.NestedHash.DeeplyNested.Level3Key | Should -Be 'Level3Value'
        }

        It 'Deeply nested structure should be an OrderedDictionary' {
            $script:jsonResult.NestedHash.DeeplyNested | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'Simple arrays should be identical' {
            $script:jsonResult.SimpleArray | Should -Be $script:yamlResult.SimpleArray
            $script:jsonResult.SimpleArray.Count | Should -Be 3
            $script:jsonResult.SimpleArray[0] | Should -Be 'Item1'
        }

        It 'Array of hashes should have the same count' {
            $script:jsonResult.ArrayOfHashes.Count | Should -Be $script:yamlResult.ArrayOfHashes.Count
            $script:jsonResult.ArrayOfHashes.Count | Should -Be 2
        }

        It 'Array of hashes entries should be OrderedDictionaries' {
            $script:jsonResult.ArrayOfHashes[0] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $script:yamlResult.ArrayOfHashes[0] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'Array of hashes values should be identical' {
            $script:jsonResult.ArrayOfHashes[0].Name | Should -Be 'First'
            $script:jsonResult.ArrayOfHashes[0].Value | Should -Be 1
            $script:jsonResult.ArrayOfHashes[1].Name | Should -Be $script:yamlResult.ArrayOfHashes[1].Name
        }
    }

    Context 'Datum handler processing' {
        BeforeAll {
            $script:jsonResult = Get-FileProviderData -Path (Join-Path -Path $jsonDataPath -ChildPath 'HandlerData.json') -DatumHandlers $datumHandlers
            $script:yamlResult = Get-FileProviderData -Path (Join-Path -Path $yamlDataPath -ChildPath 'HandlerData.yml') -DatumHandlers $datumHandlers
        }

        It 'Top-level handler values in JSON should be processed by the datum handler' {
            # The TestHandler matches [TEST=...] and returns a formatted string.
            # If the handler was NOT invoked, the raw string '[TEST=SomeParam]' would remain.
            $script:jsonResult.HandlerValue | Should -Not -Be '[TEST=SomeParam]'
        }

        It 'Top-level handler values in YAML should be processed by the datum handler' {
            $script:yamlResult.HandlerValue | Should -Not -Be '[TEST=SomeParam]'
        }

        It 'JSON and YAML handler results should be equivalent' {
            # Both should have been processed by the same handler, producing
            # equivalent output (the handler includes Action/Node/Params info).
            $script:jsonResult.HandlerValue | Should -Be $script:yamlResult.HandlerValue
        }

        It 'Nested handler values in JSON should be processed' {
            $script:jsonResult.NestedWithHandler.HandlerKey | Should -Not -Be '[TEST=AnotherParam]'
        }

        It 'Nested handler values in YAML should be processed' {
            $script:yamlResult.NestedWithHandler.HandlerKey | Should -Not -Be '[TEST=AnotherParam]'
        }

        It 'Nested regular values should be preserved unchanged' {
            $script:jsonResult.NestedWithHandler.RegularKey | Should -Be 'RegularValue'
            $script:yamlResult.NestedWithHandler.RegularKey | Should -Be 'RegularValue'
        }

        It 'JSON and YAML nested handler results should be equivalent' {
            $script:jsonResult.NestedWithHandler.HandlerKey | Should -Be $script:yamlResult.NestedWithHandler.HandlerKey
        }

        It 'Handler values inside arrays in JSON should be processed' {
            $script:jsonResult.ArrayWithHandler[1] | Should -Not -Be '[TEST=ThirdParam]'
        }

        It 'Handler values inside arrays in YAML should be processed' {
            $script:yamlResult.ArrayWithHandler[1] | Should -Not -Be '[TEST=ThirdParam]'
        }

        It 'Regular values inside arrays should be preserved' {
            $script:jsonResult.ArrayWithHandler[0] | Should -Be 'NormalItem'
            $script:yamlResult.ArrayWithHandler[0] | Should -Be 'NormalItem'
        }

        It 'JSON and YAML array handler results should be equivalent' {
            $script:jsonResult.ArrayWithHandler[1] | Should -Be $script:yamlResult.ArrayWithHandler[1]
        }
    }

    Context 'Data accessed through the existing DSC_ConfigData hierarchy' {
        BeforeAll {
            $datumPath = Join-Path -Path $here -ChildPath 'assets\DSC_ConfigData\Datum.yml'
            $script:datum = New-DatumStructure -DefinitionFile $datumPath
        }

        It 'JSON file (Subkey2.json) should be accessible through the hierarchy' {
            $script:datum.Roles.Role2.Subkey2 | Should -Not -BeNullOrEmpty
        }

        It 'JSON file data should be an OrderedDictionary after ConvertTo-Datum processing' {
            $script:datum.Roles.Role2.Subkey2 | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'JSON file data should contain the expected value' {
            $script:datum.Roles.Role2.Subkey2.subkey2value | Should -Be 'yeah!'
        }

        It 'YAML file (Subkey1.yml) should also be an OrderedDictionary for consistency' {
            $script:datum.Roles.Role2.Subkey1 | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'JSON and YAML sibling files should both be accessible with consistent types' {
            $script:datum.Roles.Role2.Subkey2.GetType().Name | Should -Be $script:datum.Roles.Role2.Subkey1.GetType().Name
        }
    }

    Context 'File provider cache treats JSON same as YAML' {
        BeforeAll {
            # Clear any existing cache
            $script:jsonPath = Join-Path -Path $jsonDataPath -ChildPath 'SimpleData.json'
            $script:yamlPath = Join-Path -Path $yamlDataPath -ChildPath 'SimpleData.yml'

            # First call populates cache
            $script:firstJson = Get-FileProviderData -Path $script:jsonPath -DatumHandlers $datumHandlers
            $script:firstYaml = Get-FileProviderData -Path $script:yamlPath -DatumHandlers $datumHandlers

            # Second call should hit cache
            $script:secondJson = Get-FileProviderData -Path $script:jsonPath -DatumHandlers $datumHandlers
            $script:secondYaml = Get-FileProviderData -Path $script:yamlPath -DatumHandlers $datumHandlers
        }

        It 'Cached JSON result should be identical to first result' {
            $script:secondJson.SimpleString | Should -Be $script:firstJson.SimpleString
            $script:secondJson.SimpleInt | Should -Be $script:firstJson.SimpleInt
        }

        It 'Cached YAML result should be identical to first result' {
            $script:secondYaml.SimpleString | Should -Be $script:firstYaml.SimpleString
            $script:secondYaml.SimpleInt | Should -Be $script:firstYaml.SimpleInt
        }

        It 'Cached JSON result type should still be OrderedDictionary' {
            $script:secondJson | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }
    }

    Context 'Error handling for invalid JSON files' {
        BeforeAll {
            $script:invalidJsonPath = Join-Path -Path $TestDrive -ChildPath 'Invalid.json'
            # Unclosed brace — invalid in both JSON and YAML
            '{"key": "value"' | Set-Content -Path $script:invalidJsonPath -Encoding utf8

            $script:invalidYamlPath = Join-Path -Path $TestDrive -ChildPath 'Invalid.yml'
            'key: [unclosed' | Set-Content -Path $script:invalidYamlPath -Encoding utf8
        }

        It 'Invalid JSON should produce an error mentioning JSON and the file path' {
            { Get-FileProviderData -Path $script:invalidJsonPath } | Should -Throw -ExpectedMessage '*JSON*'
        }

        It 'Invalid JSON error should mention the file path' {
            { Get-FileProviderData -Path $script:invalidJsonPath } | Should -Throw -ExpectedMessage "*$($script:invalidJsonPath)*"
        }

        It 'Invalid YAML should throw a native YAML error (not wrapped)' {
            { Get-FileProviderData -Path $script:invalidYamlPath } | Should -Throw
        }
    }
}
