using module datum

Remove-Module -Name datum -ErrorAction SilentlyContinue

Describe 'Merge-Datum: empty-array regression (issue #173)' {

    BeforeAll {
        Import-Module -Name datum -Force
        $datumModule = Get-Module datum

        # Minimal $script:Datum stub.
        # Merge-Datum reads $Datum.__Definition.DatumHandlers (via Invoke-DatumHandler)
        # and $Datum.__Definition.default_json_depth (for verbose serialization).
        $datumStub = [pscustomobject]@{
            __Definition = @{
                DatumHandlers      = @{}
                default_json_depth = 4
            }
        }

        # Inject the stub into the module's session state. We use [scriptblock]::Create
        # so the scriptblock is unbound and adopts the module's session state when
        # invoked via `& $module`, ensuring the assignment hits the module's
        # $script:Datum (not the test file's).
        & $datumModule ([scriptblock]::Create('param($d) $script:Datum = $d')) $datumStub
    }

    Context 'Empty array vs populated array (the bug)' {
        # These cases must NOT raise the spurious type-mismatch warning.
        # On unpatched 0.40.x they DO, because Get-DatumType classifies @() as
        # 'baseType_array' (since @() -as [hashtable[]] returns $null), which then
        # falsely mismatches a populated 'hash_array' on the other side.

        It 'does not warn "Cannot merge different types" when REF is @() and DIFF is hash_array' {
            $ref  = @()
            $diff = @(
                @{ Name = 'Alice'; Role = 'Admin' }
                @{ Name = 'Bob';   Role = 'User'  }
            )

            $null = Merge-Datum `
                -StartingPath 'Users' `
                -ReferenceDatum $ref `
                -DifferenceDatum $diff `
                -Strategies @{ '^.*' = 'MostSpecific' } `
                -WarningAction SilentlyContinue `
                -WarningVariable warnings

            $warnings |
                Where-Object { $_ -match 'Cannot merge different types' } |
                Should -BeNullOrEmpty
        }

        It 'does not warn "Cannot merge different types" when REF is hash_array and DIFF is @()' {
            $ref = @(
                @{ Name = 'Alice'; Role = 'Admin' }
                @{ Name = 'Bob';   Role = 'User'  }
            )
            $diff = @()

            $null = Merge-Datum `
                -StartingPath 'Users' `
                -ReferenceDatum $ref `
                -DifferenceDatum $diff `
                -Strategies @{ '^.*' = 'MostSpecific' } `
                -WarningAction SilentlyContinue `
                -WarningVariable warnings

            $warnings |
                Where-Object { $_ -match 'Cannot merge different types' } |
                Should -BeNullOrEmpty
        }

        It 'does not warn "Cannot merge different types" when REF is hash_array and DIFF is @() with Sum strategy' {
            # Same as above but with a Sum strategy: empty + populated must yield populated.
            $ref = @(
                @{ Name = 'Alice'; Role = 'Admin' }
                @{ Name = 'Bob';   Role = 'User'  }
            )
            $diff = @()

            $null = Merge-Datum `
                -StartingPath 'Users' `
                -ReferenceDatum $ref `
                -DifferenceDatum $diff `
                -Strategies @{ '^.*' = @{ merge_hash_array = 'Sum' } } `
                -WarningAction SilentlyContinue `
                -WarningVariable warnings

            $warnings |
                Where-Object { $_ -match 'Cannot merge different types' } |
                Should -BeNullOrEmpty
        }

        It 'does not warn "Cannot merge different types" when both REF and DIFF are empty' {
            $null = Merge-Datum `
                -StartingPath 'Users' `
                -ReferenceDatum @() `
                -DifferenceDatum @() `
                -Strategies @{ '^.*' = 'MostSpecific' } `
                -WarningAction SilentlyContinue `
                -WarningVariable warnings

            $warnings |
                Where-Object { $_ -match 'Cannot merge different types' } |
                Should -BeNullOrEmpty
        }
    }

    Context 'Genuine type mismatch (regression guard)' {
        # The fix must NOT silence legitimate type-mismatch warnings.

        It 'still warns "Cannot merge different types" when REF is baseType_array and DIFF is hash_array' {
            $ref  = @('alpha', 'beta')                            # baseType_array
            $diff = @(@{ Name = 'Alice' }, @{ Name = 'Bob' })     # hash_array

            $null = Merge-Datum `
                -StartingPath 'Mixed' `
                -ReferenceDatum $ref `
                -DifferenceDatum $diff `
                -Strategies @{ '^.*' = 'MostSpecific' } `
                -WarningAction SilentlyContinue `
                -WarningVariable warnings

            $warnings |
                Where-Object { $_ -match 'Cannot merge different types' } |
                Should -Not -BeNullOrEmpty
        }

        It 'still warns "Cannot merge different types" when REF is hashtable and DIFF is hash_array' {
            $ref  = @{ Name = 'Alice' }                            # hashtable
            $diff = @(@{ Name = 'Alice' }, @{ Name = 'Bob' })      # hash_array

            $null = Merge-Datum `
                -StartingPath 'Mixed' `
                -ReferenceDatum $ref `
                -DifferenceDatum $diff `
                -Strategies @{ '^.*' = 'MostSpecific' } `
                -WarningAction SilentlyContinue `
                -WarningVariable warnings

            $warnings |
                Where-Object { $_ -match 'Cannot merge different types' } |
                Should -Not -BeNullOrEmpty
        }
    }
}