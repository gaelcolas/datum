Important Note:

a lookup done at different 'layers' of the hierarchy (different PropertyPath) will return different value at the same property path:

```PowerShell
(lookup MergeTest1).MergeHash

# Name                           Value
# ----                           -----
# HashKey2                       FromEnvironment
# HashKey3                       FromEnvironment

lookup MergeTest1\MergeHash

# Name                           Value
# ----                           -----
# HashKey2                       FromEnvironment
# HashKey3                       FromEnvironment
# HashKey1                       FromRole

```





```
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
    #       --> $ref + $diff | ? % key in Tuple_Keys -> $ref[Key] -eq $diff[key] is not already int output
    #      DeepTuple
    #       --> $ref + $diff | ? % key in Tuple_Keys -> $ref[Key] -eq $diff[key] is merged up
    #      Sum
    #       --> $ref + $diff
    #   merge_options:
    #     knockout_prefix: --
    #     Tuple_Keys:
    #       - Name
    #       - Version
```