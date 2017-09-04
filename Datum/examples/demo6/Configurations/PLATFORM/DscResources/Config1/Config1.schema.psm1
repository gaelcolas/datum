Configuration Config1 {
    Param(
        $Param1 = $(Lookup $Node 'Path\to\data')
    )

    File 'Config1' {
        DestinationPath = 'C:\blah.txt'
        Contents = $Param1
    }
}