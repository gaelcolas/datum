<#
MergeStrategy: MostSpecific
        merge_hash: MostSpecific
        merge_baseType_array: MostSpecific
        merge_hash_array: MostSpecific

MergeStrategy: hash
        merge_hash: hash
        merge_baseType_array: MostSpecific
        merge_hash_array: MostSpecific
        merge_options:
        knockout_prefix: --

MergeStrategy: Deep
        merge_hash: deep
        merge_baseType_array: Unique
        merge_hash_array: DeepTuple
        merge_options:
        knockout_prefix: --
        Tuple_Keys:
            - Name
            - Version
#>
function Get-MergeStrategyFromString {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [String]
        $MergeStrategy
    )
    
    Write-Debug "Get-MergeStrategyFromString -MergeStrategy <$MergeStrategy>"
    switch -regex ($MergeStrategy) {
        '^First$|^MostSpecific$' { 
            @{
                merge_hash = 'MostSpecific'
                merge_baseType_array = 'MostSpecific'
                merge_hash_array = 'MostSpecific'
            }
        }

        '^hash$|^MergeTopKeys$' {
            @{
                merge_hash = 'hash'
                merge_baseType_array = 'MostSpecific'
                merge_hash_array = 'MostSpecific'
                merge_options = @{
                    knockout_prefix = '--'
                }
            }
        }

        '^deep$|^MergeRecursively$' {
            @{
                merge_hash = 'deep'
                merge_baseType_array = 'Unique'
                merge_hash_array = 'DeepTuple'
                merge_options = @{
                    knockout_prefix = '--'
                    tuple_keys = @(
                        'Name'
                        ,'Version'
                    )
                }
            }
        }
        default {
            Write-Debug "Couldn't Match the strategy $MergeStrategy"
            @{
                merge_hash = 'MostSpecific'
                merge_baseType_array = 'MostSpecific'
                merge_hash_array = 'MostSpecific'
            }
        }
    }
    
}