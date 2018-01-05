function Get-MergeStrategyFromString {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [String]
        $MergeStrategy
    )

    switch -regex ($MergeStrategy) {
        '^First$|^MostSpecific$' { 
            @{
                strategy = 'MostSpecific'
            }
        }
        
        '^Unique$|^ArrayUniques$' {
            @{
                strategy = 'Unique'
            }
        }

        '^hash$|^MergeTopKeys$' {
            @{
                strategy = 'hash'
                options = @{
                    knockout_prefix    = '--'
                    sort_merged_arrays = $false
                    merge_hash_arrays  = $false
                }
            }
        }

        '^deep$|^MergeRecursively$' {
            @{
                strategy = 'deep'
                options = @{
                    knockout_prefix    = '--'
                    sort_merged_arrays = $false
                    merge_hash_arrays  = $false
                }
            }
        }
        default {
            Write-Verbose "Couldn't Match the strategy $MergeStrategy"
            @{
                strategy = 'MostSpecific'
            }
        }
    }
    
}