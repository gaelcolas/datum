<#
    Datum Structure is a PSCustomObject 
     To that object we add DatumStores as Script Properties/Class instances
      Those Properties embed the mechanism to call the container hierarchy and the RAW value of the items
       The format of the item defines its method of conversion from raw to Object 
#>

function New-DatumStructure {
    Param (
        $Structure
    )
    
    $root = @{}
    foreach ($store in $Structure.DatumStructure){
        $StoreParams = Convertto-hashtable $Store.StoreOptions 
        $cmd = Get-Command ("{0}\New-Datum{1}Provider" -f ($store.StoreProvider -split '::'))
        $storeObject = &$cmd @StoreParams
        $root.Add($store.StoreName,$storeObject)
    }
    [PSCustomObject]$root
}