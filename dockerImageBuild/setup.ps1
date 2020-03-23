#
################# Dangerous to use appveyor links - the builds are removed after 6 months
#
#ARG FLUENTBIT_URL=https://ci.appveyor.com/api/buildjobs/37lho3xf8j5i6crj/artifacts/build%2Ftd-agent-bit-1.4.0-win64.zip

Write-Host ('Cleaning up existing folders')
    $folders = ["/installation", "/omsagentwindows", "/fluent-bit"]
    if (Test-Path $folder) { Remove-Item $folder -Recurse; }
    Remove-Item /installation -Recurse -Force -Confirm:$false
    Remove-Item /omsagentwindows -Recurse -Force -Confirm:$false
    Remove-Item /fluent-bit -Recurse -Force -Confirm:$false

Write-Host ('Creating folders')
    New-Item -Type Directory -Path /installation -ErrorAction SilentlyContinue
    New-Item -Type Directory -Path /fluent-bit -ErrorAction SilentlyContinue

Push-Location \installation

Write-Host('Downloading windows fluent bit container package')
    $windowsLogPackageUri = "https://github.com/r-dilip/goPlugins-fluentbit/releases/download/windowsakslog/windows-log-aks-package.zip" 
    $windowsLogAksPackageLocation = "\installation\windows-log-aks-package.zip"
    Invoke-WebRequest -Uri $windowsLogPackageUri -OutFile $windowsLogAksPackageLocation
Write-Host ("Finished downloading fluent bit package for windows logs")

Write-Host ('Installing Fluent Bit'); 
    $fluentBitUri='https://github.com/bragi92/windowslog/raw/master/td-agent-bit-1.4.0-win64.zip'
    Invoke-WebRequest -Uri $fluentBitUri -OutFile /installation/td-agent-bit.zip
    Expand-Archive -Path /installation/td-agent-bit.zip -Destination /installation/fluent-bit
    Move-Item -Path /installation/fluent-bit/*/* -Destination /fluent-bit/ -ErrorAction SilentlyContinue
Write-Host ('Finished Installing Fluentbit')

Write-Host ('Installing Ruby')
    $RUBY_VERSION='2.7.0-1'
    $RUBY_EXE_LOCATION = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-$RUBY_VERSION/rubyinstaller-$RUBY_VERSION-x64.exe"
    $rubyExePath = "\installation\ruby-install.exe"
    $rubyArgs = "/silent /dir=\Ruby /tasks='assocfiles,modpath'"

    Invoke-WebRequest -Uri $RUBY_EXE_LOCATION -OutFile $rubyExePath
    $ruby_inst_process = Start-Process -FilePath $rubyExePath -ArgumentList $rubyArgs -PassThru -Wait
    if ($ruby_inst_process.ExitCode -ne 0) {
        "Ruby $RUBY_VERSION installation failed"
        exit 1
    }
Write-Host ('Finished Installing Ruby')


Write-Host ('Installing Visual C++ Redistributable Package')
    $vcRedistLocation = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
    $vcInstallerLocation = "\installation\vc_redist.x64.exe"
    $vcArgs = "/install /quiet /norestart"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $vcRedistLocation -OutFile $vcInstallerLocation
    $ProgressPreference = 'Continue'
    Start-Process $vcInstallerLocation -ArgumentList $vcArgs -NoNewWindow -Wait
    Copy-Item -Path /Windows/System32/msvcp140.dll -Destination /fluent-bit/bin
    Copy-Item -Path /Windows/System32/vccorlib140.dll -Destination /fluent-bit/bin 
    Copy-Item -Path /Windows/System32/vcruntime140.dll -Destination /fluent-bit/bin
Write-Host ('Finished Installing Visual C++ Redistributable Package')

Write-Host ("Extracting windows fluent-bit package")
    $fluentBitPath = "\omsagentwindows"
    New-Item -Type Directory -Path $fluentBitPath
    Expand-Archive -Path $windowsLogAksPackageLocation -Destination $fluentBitPath -ErrorAction SilentlyContinue
Write-Host ("Finished Extracting fluentbit package")

Pop-Location