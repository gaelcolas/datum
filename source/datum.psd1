
@{

    RootModule        = 'datum.psm1'

    ModuleVersion     = '0.0.1'

    GUID              = 'e176662d-46b8-4900-8de5-e84f9b4366ee'

    Author            = 'Gael Colas'

    CompanyName       = 'SynEdgy Limited'

    Copyright         = '(c) 2020 Gael Colas. All rights reserved.'

    Description       = 'Module to manage Hierarchical Configuration Data.'

    PowerShellVersion = '5.1'

    RequiredModules   = @(
        'powershell-yaml'
    )

    ScriptsToProcess  = @(
        './ScriptsToProcess/Resolve-NodeProperty.ps1'
    )

    FunctionsToExport = ''

    AliasesToExport   = ''

    PrivateData       = @{

        PSData = @{

            Tags         = @('Datum', 'Hiera', 'DSC', 'DesiredStateConfiguration', 'hierarchical', 'ConfigurationData', 'ConfigData')

            LicenseUri   = 'https://github.com/gaelcolas/Datum/blob/master/LICENSE'

            ProjectUri   = 'https://github.com/gaelcolas/Datum/'

            ReleaseNotes = ''

            Prerelease   = ''

        }
    }
}
