function Merge-Hashtable {
    [outputType([hashtable])]
    [cmdletBinding()]
    Param(
        # [hashtable] These should stay ordered
        $ReferenceHashtable,

        # [hashtable] These should stay ordered
        $DifferenceHashtable,

        [validateScript(
            {   $_ -as [hashtable] -and $_.strategy -in @('hash','deep') -or
                $_ -in @('hash','deep')
            }
        )]
        $Strategy = @{
                Strategy = 'deep'
                options = @{
                    knockoutprefix = '--'
                }
            },
        
        $ChildStrategies = @{},

        [string]
        $ParentPath
    )
    
    Write-Debug "`tMerge-Hashtable -ParentPath <$ParentPath>"
    # Removing Case Sensitivity while keeping ordering
    $ReferenceHashtable  = [ordered]@{} + $ReferenceHashtable
    $DifferenceHashtable = [ordered]@{} + $DifferenceHashtable
    $clonedReference     = [ordered]@{} + $ReferenceHashtable

    if ($Strategy.options.knockout_prefix) {
        $KnockoutPrefix = $Strategy.options.knockout_prefix
        $KnockoutPrefixMatcher = [regex]::escape($KnockoutPrefix).insert(0,'^')
    }
    else {
        $KnockoutPrefixMatcher = [regex]::escape('--').insert(0,'^')
    }
    Write-Debug "`t  Knockout Prefix Matcher: $knockoutPrefixMatcher"

    if($strategy -eq 'deep' -or $strategy.Strategy -eq 'deep') {
        $deepmerge = $true
    }
    else {
        $deepmerge = $false
    }

    $knockedOutKeys = $ReferenceHashtable.keys.where{$_ -match $KnockoutPrefixMatcher}.foreach{$_ -replace $KnockoutPrefixMatcher} 
    Write-Debug "`t  Knockedout Keys: [$($knockedOutKeys -join ', ')] from reference Hashtable Keys [$($ReferenceHashtable.keys -join ', ')]"

    foreach ($currentKey in $DifferenceHashtable.keys) {
        Write-Debug "`t  CurrentKey: $currentKey"
        if($currentKey -in $knockedOutKeys) {
            Write-Debug "`t`tThe Key $currentkey is knocked out from the reference Hashtable."
        }
        elseif ($currentKey -match $KnockoutPrefixMatcher -and !$ReferenceHashtable.contains(($currentKey -replace $KnockoutPrefixMatcher))) {
            # it's a knockout coming from a lower level key, it should only apply down from here
            Write-Debug "`t`tKnockout prefix found for $currentKey in Difference hashtable, and key not set in Reference hashtable"
            if(!$ReferenceHashtable.contains($currentKey)) {
                Write-Debug "`t`t..adding knockout prefixed key for $curretKey to block further merges"
                $clonedReference.add($currentKey,$null)
            }
        }
        elseif (!$ReferenceHashtable.contains($currentKey) )  {
            #if the key does not exist in reference ht, create it using the DiffHt's value
            Write-Debug "`t    Added Missing Key $currentKey of value: $($DifferenceHashtable[$currentKey]) from difference HT"
            $clonedReference.add($currentKey,$DifferenceHashtable[$currentKey])
        }
        else { #the key exists, and it's not a knockout entry
            if ( $deepmerge -and ($ReferenceHashtable[$currentKey] -as [hashtable] -or
                 # Or is an arry/list
                 ( $ReferenceHashtable[$currentKey] -is [System.Collections.IEnumerable] -and
                   $ReferenceHashtable[$currentKey] -isnot [string])
                 )
               ) 
            {
                # both are hashtables and we're in Deepmerge mode
                $ChildPath = (Join-Path  $ParentPath $currentKey)
                Write-Debug "`t`t .. Merging Datums at current path $ChildPath"
                # if there's no Merge override for the subkey's path in the (not subkeys), 
                #   merge HASHTABLE with same strategy
                # otherwise, merge Datum
                $ChildStrategy = Get-MergeStrategyFromPath -Strategies $ChildStrategies -PropertyPath $ChildPath
                
                if($ChildStrategy.Default) {
                    Write-Debug "`t`t ..Merging using the current Deep Strategy, Bypassing default"
                    $MergePerDefault = @{
                        ParentPath = $ChildPath
                        Strategy = $Strategy
                        ReferenceHashtable = $ReferenceHashtable[$currentKey]
                        DifferenceHashtable = $DifferenceHashtable[$currentKey]
                        ChildStrategies = $ChildStrategies
                    }
                    $subMerge = Merge-Hashtable @MergePerDefault
                }
                else {
                    Write-Debug "`t`t ..Merging using Override Strategy $($ChildStrategy|ConvertTo-Json)"
                    $MergeDatumParam = @{
                        StartingPath = $ChildPath
                        ReferenceDatum = $ReferenceHashtable[$currentKey]
                        DifferenceDatum = $DifferenceHashtable[$currentKey] 
                        Strategies = $ChildStrategies
                    }
                    $subMerge = Merge-Datum @MergeDatumParam
                }
                Write-Debug "`t  # Submerge $($submerge|ConvertTo-Json)."
                $clonedReference[$currentKey]  = $subMerge
            }  ####################### ---> add array merge and hashtable[] merge here (hashtable[] merge based on defined subkey)
            else {
                #one is not an hashtable or we're not in deepmerge mode, leave the ClonedReference as-is
                Write-debug "`t    Using BaseType $($ReferenceHashtable[$currentKey].GetType()) from Ref[$currentkey] of value $($ReferenceHashtable[$currentKey])" #";  Diff[$currentkey] type $($DifferenceHashtable[$currentKey].GetType())" 
            }
        }
    }

    return $clonedReference
    
}

<#
$a = @{
    keya = 1
    keyb = 2
    keyc = 3
    '--keye' = $null
}

$b = @{
    '--keya' = $null # removing keya
    keyb = 22        # won't override keyb
    keyd = 33        # will add keyd with value
    keye = 44        # keye should never be added, as it's removed from the ref ht
}

# simple merge: create keys from $b that do not exist in $a, remove --keys

$d = [ordered]@{
    a = [ordered]@{
        x = 111
        y = 222
        z = 333
    }
    b = 2
    c = 3
    d = 4
    e = [ordered]@{
        x = 111
        '--y' = $null
    }
}

$c = @{
    b = 0 #already defined, should ignore
    '--c' = $null #doesn't remove the key c from $c as it would violate the hierarchy
    #d missing intentionally, already defined
    e = @{
        # key x omitted, already present
        y = 222 # this key 'y' should be added to $c.e
        z = 333 # this key 'z' should be added to $c.e
    }
}

$e = [ordered]@{
    RootKey1 = [ordered]@{
        subkey11 = [ordered]@{
            subkey111 = 111
            #'--Subkey112' = $null
            Subkey113 = 113
        }
        subkey12 = [ordered]@{
            subkey123 = 123
            subkey124 = 124 
        }
    }
    RootKey2 = [ordered]@{
        Subkey21 = [ordered]@{
            Subkey211 = 211
            Subkey212 = 212
            Subkey213 = 213
        }
        Subkey22 = @(
            222
            223
            224
        )
        SubKey23 = @(
            [ordered]@{Name = 1; val1 = 1}
            [ordered]@{Name = 2; val1 = 2}
            [ordered]@{Name = 3; val1 = 3}
        )
    }
}

$f = [ordered]@{
    RootKey1 = [ordered]@{
        subkey11 = [ordered]@{
            subkey111 = 111
            Subkey112 = 112
            Subkey113 = 113
        }
        subkey12 = [ordered]@{
            subkey123 = 123
            subkey124 = 124 
        }
    }
    RootKey2 = [ordered]@{
        Subkey21 = [ordered]@{
            Subkey211 = 2110
            Subkey212 = 2120
            Subkey213 = 2130
        }
        Subkey22 = @(
            221
        )
        SubKey23 = @(
            [ordered]@{Name = 1; val1 = 1}
            [ordered]@{Name = 2; val1 = 3}
            [ordered]@{Name = 3}
        )
    }
}

$MergeParams = @{
    StartingPath = 'root'

    ReferenceDatum =  $e

    DifferenceDatum = $f

    Strategies = @{
        'root' = 'deep'
        'root\rootkey2\Subkey22' = 'Unique'
        'root\rootkey2\Subkey23' = 'Unique'
        '^.*' = 'deep'
    }
}
Merge-Datum @MergeParams
#>