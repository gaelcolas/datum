@{
    Name = 'Site01'
    ExampleProperty1 = 'From Site'
    ExampleProperty2 = 'From Site'
    ExampleProperty3 = 'From Site'
    Roles = @{
        FileServer = @{
            datum = @{
                mergeMe = @{Site = 'From Site';b='bar'}
            }
        }
    }
}

