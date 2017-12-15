Class FileProvider {
    hidden $Path
    hidden [hashtable] $DataOptions
    hidden [io.fileInfo]$DatumConfig
    
    FileProvider ($Path,$DataOptions)
    {
        $this.DataOptions = $DataOptions
        $this.Path = Get-Item $Path -ErrorAction SilentlyContinue
        
        $Result = Get-ChildItem $path | ForEach-Object {
            if($_.PSisContainer) {
                $val = [scriptblock]::Create("New-DatumFileProvider -Path `"$($_.FullName)`" -DataOptions `$this.DataOptions")
                $this | Add-Member -MemberType ScriptProperty -Name $_.BaseName -Value $val
            }
            else {
                $val = [scriptblock]::Create("Get-FileProviderData -Path  `"$($_.FullName)`" -DataOptions `$this.DataOptions")
                $this | Add-Member -MemberType ScriptProperty -Name $_.BaseName -Value $val
            }
        }
    }
}

#$ConfigurationData = [fileProvider]::new($PWD.Path,@{})
#($ConfigurationData.AllNodes.psobject.Properties | % { $ConfigurationData.AllNodes.($_.Name) })[1]