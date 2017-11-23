if(
    $env:ProjectName -and $ENV:ProjectName.Count -eq 1 -and
    $env:BuildSystem -eq 'AppVeyor'
   )
{
    Write-Host "PR: $Env:APPVEYOR_PULL_REQUEST_NUMBER"
    if (!$Env:APPVEYOR_PULL_REQUEST_NUMBER -and $Env:BuildSystem -eq 'AppVeyor' -and $Env:BranchName -eq 'master' -and $Env:NuGetApiKey) {
        Deploy Module {
            By PSGalleryModule {
                FromSource $(Get-Item ".\BuildOutput\$Env:ProjectName")
                To PSGallery
                WithOptions @{
                    ApiKey = $Env:NuGetApiKey
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