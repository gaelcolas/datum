@{
    BaseServerSettings = @{
        PowerPlan = 'Balanced'
    }
    
    datum = @{
        mergeMe = @{Role = 'From Role';}
    }

    FileServerSettings = @{
        Shares = @(
            @{
                Name = 'Websites$'
                Path = 'D:\Shares\Websites'
                FullAccess = @('BUILTIN\Administrators')
                ReadAccess = @('NT AUTHORITY\Authenticated Users')
            }
        )
    }

    ExampleProperty1 = 'From Role'
}

