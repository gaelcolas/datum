function Get-MergeStrategyFromString {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [String]
        $MergeStrategy
    )

    # if $ref is a
    #   base type:
    #       --> Return $ref
    #   hash
    #     MostSpecific
    #       --> Return $ref
    #     Hash
    #       --> Merge Hashtable keys
    #     deep
    #       --> Merge Hashtable keys recursively, pushing down the strategy until lookup_option override
    #   baseType Array
    #      MostSpecific
    #       --> Return $ref
    #      Unique
    #       --> ($ref + $Diff -$kop)|Select-Unique
    #      Sum
    #       --> $ref + $diff -$kop
    #   hash_array
    #      MostSpecific
    #       --> Return $ref
    #      UniqueKeyValTuples
    #       --> $ref + $diff | ? % key in TupleKeys -> $ref[Key] -eq $diff[key] is not already int output
    #      DeepTuple
    #       --> $ref + $diff | ? % key in TupleKeys -> $ref[Key] -eq $diff[key] is merged up
    #      Sum
    #       --> $ref + $diff
    #   merge_options:
    #     knockout_prefix: --
    #     TupleKeys:
    #       - Name
    #       - Version

    Write-Debug "Get-MergeStrategyFromString -MergeStrategy <$MergeStrategy>"
    
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
            TupleKeys:
              - Name
              - Version
    #>

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