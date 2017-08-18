if($PSScriptRoot) {
    $here = $PSScriptRoot
} else {
    $here = 'C:\src\Datum\Datum\examples\demo4'
}
pushd $here

ipmo $here\..\..\Datum.psd1 -force

configuration MyConfiguration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    node localhost
    {
        x File MySplatTest @{
            DestinationPath = 'C:\Configurations\Test.txt'
            Contents = 'this is my content'
        }

        x File MySplatTest2 @{
            DestinationPath = 'C:\Configurations\Test2.txt'
            Contents = 'this is my content'
            DependsOn = '[File]MySplatTest'
        }
    }
}

MyConfiguration

(cat -raw .\MyConfiguration\localhost.mof) -replace '\\n',"`r`n"

#popd