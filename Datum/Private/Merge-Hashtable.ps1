function Merge-Hashtable {
    [outputType([hashtable])]
    [cmdletBinding()]
    Param(
        [hashtable]
        $ReferenceHashtable,

        [hashtable]
        $DifferenceHashtable,

        [validateScript(
            {   $_ -as [hashtable] -and $_.strategy -in @('hash','deep') -or
                $_ -in @('hash','deep')
            }
        )]
        $Strategy = @{
                Strategy = 'deep'
                knockoutprefix = '--'
            },
        
        [hashtable[]]
        $ChildStrategies = @(),

        [string]
        $ParentPath
    )
    

    $clonedReference = $ReferenceHashtable.Clone()
    if ($Strategy.knockoutprefix) {
        $KnockoutPrefix = $Strategy.knockoutprefix
        $KnockoutPrefixMatcher = [regex]::escape($KnockoutPrefix).insert(0,'^')
    }

    if($strategy -eq 'deep' -or $strategy.Strategy -eq 'deep') {
        $deepmerge = $true
    }
    else {
        $deepmerge = $false
    }

    $knockedOutKeys = $ReferenceHashtable.keys.where{$_ -match $KnockoutPrefixMatcher}.foreach{$_ -replace $KnockoutPrefixMatcher} 

    foreach ($currentKey in $DifferenceHashtable.keys) {

        if($currentKey -in $knockedOutKeys) {
            Write-Debug "The Key $currentkey is knocked out from the reference Hashtable."
        }
        elseif ($currentKey -match $KnockoutPrefixMatcher -and !$ReferenceHashtable.contains(($currentKey -replace $KnockoutPrefixMatcher))) {
            # it's a knockout coming from a lower level key, it should only apply down from here
            Write-Debug "Knockout prefix found for $currentKey in Difference hashtable, and key not set in Reference hashtable"
            if(!$ReferenceHashtable.contains($currentKey)) {
                Write-Debug "adding knockout prefixed key for $curretKey to block further merges"
                $clonedReference.add($currentKey,$null)
            }
            #Write-Warning "Removed key $($currentKey -replace $KnockoutPrefixMatcher) as we found the knockout prefix $KnockoutPrefix in the difference object"
            #$clonedReference.remove(($currentKey -replace $KnockoutPrefixMatcher))
        }
        elseif (!$ReferenceHashtable.contains($currentKey) )  {
            #if the key does not exist in reference ht, create it using the DiffHt's value
            Write-Debug "Added Key $currentKey using the DifferenceHashtable value: $($DifferenceHashtable[$currentKey]| Format-List * | out-String)"
            $clonedReference.add($currentKey,$DifferenceHashtable[$currentKey])
        }
        else { #the key exists, and it's not a knockout entry
            if ($deepmerge -and $DifferenceHashtable[$currentKey] -as [hashtable] -and $ReferenceHashtable[$currentKey] -as [hashtable]) {
                # both are hashtables and we're in Deepmerge mode
                $clonedReference[$currentKey] = Merge-Hashtable -ReferenceHashtable $ReferenceHashtable[$currentKey] -DifferenceHashtable $DifferenceHashtable[$currentKey] -Strategy $Strategy
            }  ####################### ---> add array merge and hashtable[] merge here (hashtable[] merge based on defined subkey)
            else {
                #one is not an hashtable or we're not in deepmerge mode, leave the ClonedReference as-is
                Write-Debug "Deepmerge: $deepmerge; Ref[$currentkey] type $($ReferenceHashtable[$currentKey].GetType());  Diff[$currentkey] type $($DifferenceHashtable[$currentKey].GetType())" 
            }

        }
    }

    return $clonedReference
    
}

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

$c = [ordered]@{
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

$d = @{
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

break
RootKey1: Deep + $KnockoutPrefix
RootKey1\subkey11: hash + $KnockoutPrefix
Rootkey2\subkey23: hash[] merge by Property Name

