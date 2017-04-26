@{
    Name = 'FileServer01'
    Role = 'FileServer'
    Location = 'Site01'
    NodeName = '718aec80-e8fe-41b5-ac31-fbcd5d0186b1'
    ExampleProperty1 = 'From Node'
    Roles = @{
        FileServer = @{
            datum = @{
                mergeMe = @{Node = 'From Node'; a = 1}
            }
        }
    }
}

