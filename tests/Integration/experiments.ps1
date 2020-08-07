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


Write-Warning "Lookup <Configurations> for $($Node.Name)"
Lookup Configurations

Write-Warning "Lookup <MergeTest1> for $($Node.Name)"
Lookup MergeTest1

Write-Warning "Lookup <Configurations> -Node 'SRV02"
Lookup MergeTest1 -Node 'SRV02'

Write-Warning "Lookup MergeTest1 for $($Node.Name)"
$a = (lookup MergeTest1)

Write-Warning "Show MergeTest1.MergeStringArray merging result:"
$a.MergeStringArray

Write-Warning "Show MergeTest1.MergeHashArrays merging result:"
$a.MergeHashArrays|% {$_; "`r`n"}; 


 $r = Get-DatumRsop -Datum $Datum -AllNodes $Node
 $r
<#
$a = [ordered]@{
    keya = 1
    keyb = 2
    keyc = 3
    '--keye' = $null
}

$b = [ordered]@{
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
            [ordered]@{Name = 1; version = 1}
            [ordered]@{Name = 2; version = 2}
            [ordered]@{Name = 3; version = 3}
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
            [ordered]@{Name = 1; version = 1}
            [ordered]@{Name = 2; version = 3}
            [ordered]@{Name = 3; version = 2}
        )
    }
}

$MergeParams = @{
    StartingPath = 'root'

    ReferenceDatum =  $e

    DifferenceDatum = $f

    Strategies = @{
        'root' = 'deep'
        'root\rootkey2\Subkey22' = 'deep'
        'root\rootkey2\Subkey23' = 'deep'
        '^.*' = 'deep'
    }
}
Merge-Datum @MergeParams
#>