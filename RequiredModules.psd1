@{
    # Set up a mini virtual environment...
    PSDependOptions             = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
        }
    }

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = '4.10.1'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    #'DscResource.Common'        = 'latest'
    Plaster                     = 'latest'
    ModuleBuilder               = 'latest'
    ChangelogManagement         = 'latest'
    Sampler                     = 'latest'
    'Sampler.GitHubTasks'       = 'latest'

    ProtectedData               = 'latest'
    'Datum.ProtectedData'       = 'latest'
    'Datum.InvokeCommand'       = 'latest'

}
