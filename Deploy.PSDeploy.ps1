if(
    $env:ProjectName -and $ENV:ProjectName.Count -eq 1 -and
    $env:BuildSystem -eq 'AppVeyor'
   )
{
    if ($Env:BuildSystem -eq 'AppVeyor' -and $Env:BranchName -eq 'master') {
        Deploy Module {
            By PSGalleryModule {
                FromSource $(Get-Item ".\BuildOutput\$Env:ProjectName")
                To PSGallery
                WithOptions @{
                    ApiKey = $ENV:NugetApiKey
                }
            }
        }
    }

    Deploy DeveloperBuild {
        By AppVeyorModule {
            FromSource $(Get-Item ".\BuildOutput\$Env:ProjectName\$Env:ProjectName.psd1")
            To AppVeyor
            WithOptions @{
                Version = $env:APPVEYOR_BUILD_VERSION
            }
        }
    }

   
}