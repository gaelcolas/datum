function Get-MergeStrategyFromString {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [String]
        $MergeStrategy
    )
    Write-Debug "Get-MergeStrategyFromString -MergeStrategy <$MergeStrategycls>"
    
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
                    merge_basetype_arrays = $false #'MostSpecific' # or Unique
                    merge_hash_arrays = @{ # $false #or Most Specific
                        strategy = 'MostSpecificArray' #'MergeHashesByProperties' or 'UniqueByProperties'
                        #PropertyNames = 'ObjectProperty1','objectProperty2'
                    }
                }
            }
        }

        '^deep$|^MergeRecursively$' {
            @{
                strategy = 'deep'
                options = @{
                    knockout_prefix    = '--'
                    sort_merged_arrays = $false
                    merge_basetype_arrays = 'Unique' # or MostSpecific
                    merge_hash_arrays = @{ # $false #or Most Specific
                        strategy = 'MergeByPropertyTuple' # or 'Unique', or 'MostSpecific'
                        PropertyNames = 'ObjectProperty1','objectProperty2'
                    }
                }
            }
        }
        default {
            Write-Debug "Couldn't Match the strategy $MergeStrategy"
            @{
                strategy = 'MostSpecific'
            }
        }
    }
    
}