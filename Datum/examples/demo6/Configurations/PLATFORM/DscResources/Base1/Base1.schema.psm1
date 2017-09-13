configuration Base1 {
    Param (
        $BaseParam1 = 'Param from config'
    )

    File MyFile {
        Ensure = 'Present'
        DestinationPath = 'C:\test.txt'
        Contents = $BaseParam1
    }
}