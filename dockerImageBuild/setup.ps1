#
################# Dangerous to use appveyor links - the builds are removed after 6 months
#
#ARG FLUENTBIT_URL=https://ci.appveyor.com/api/buildjobs/37lho3xf8j5i6crj/artifacts/build%2Ftd-agent-bit-1.4.0-win64.zip

# Write-Host ('Cleaning up existing folders')
#     $folders = @("/installation", "/omsagentwindows", "/fluent-bit")
#     foreach ($folder in $folders) {
#         if (Test-Path $folder) { Remove-Item $folder -Recurse; }
#     }
        
Write-Host ('Creating folders')
    New-Item -Type Directory -Path /installation -ErrorAction SilentlyContinue
    New-Item -Type Directory -Path /fluent-bit -ErrorAction SilentlyContinue
    New-Item -Type Directory -Path /omsagentwindows
    New-Item -Type Directory -Path /opt

Write-Host('Downloading windows fluentbit package')
    $windowsLogPackageUri = "https://github.com/r-dilip/goPlugins-fluentbit/releases/download/windowsakslog/windows-log-aks-package.zip" 
    $windowsLogAksPackageLocation = "\installation\windows-log-aks-package.zip"
    Invoke-WebRequest -Uri $windowsLogPackageUri -OutFile $windowsLogAksPackageLocation
Write-Host ("Finished downloading fluentbit package for windows logs")

Write-Host ("Extracting windows fluentbit container package")
    $fluentBitPath = "\omsagentwindows"
    Expand-Archive -Path $windowsLogAksPackageLocation -Destination $fluentBitPath -ErrorAction SilentlyContinue
Write-Host ("Finished Extracting windows fluentbit package")


Write-Host ('Installing Fluent Bit'); 
    $fluentBitUri='https://github.com/bragi92/windowslog/raw/master/td-agent-bit-1.4.0-win64.zip'
    Invoke-WebRequest -Uri $fluentBitUri -OutFile /installation/td-agent-bit.zip
    Expand-Archive -Path /installation/td-agent-bit.zip -Destination /installation/fluent-bit
    Move-Item -Path /installation/fluent-bit/*/* -Destination /fluent-bit/ -ErrorAction SilentlyContinue
Write-Host ('Finished Installing Fluentbit')


Write-Host ('Installing Visual C++ Redistributable Package')
    $vcRedistLocation = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
    $vcInstallerLocation = "\installation\vc_redist.x64.exe"
    $vcArgs = "/install /quiet /norestart"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $vcRedistLocation -OutFile $vcInstallerLocation
    Start-Process $vcInstallerLocation -ArgumentList $vcArgs -NoNewWindow -Wait
    Copy-Item -Path /Windows/System32/msvcp140.dll -Destination /fluent-bit/bin
    Copy-Item -Path /Windows/System32/vccorlib140.dll -Destination /fluent-bit/bin 
    Copy-Item -Path /Windows/System32/vcruntime140.dll -Destination /fluent-bit/bin
Write-Host ('Finished Installing Visual C++ Redistributable Package')

Remove-Item /installation -Recurse

Write-Host ("Removing Install folder")