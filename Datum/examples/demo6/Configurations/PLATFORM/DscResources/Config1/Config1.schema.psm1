Configuration Config1 {
    Param(
        $Config1Param1 = 'blahblah' #$(Lookup $Node 'Path\to\data')
    )

    File 'Config1' {
        Ensure = 'present'
        DestinationPath = 'C:\blah.txt'
        Contents = $Config1Param1
    }
}