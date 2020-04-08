function Confirm-WindowsServiceExists($name)
{   
    if (Get-Service $name -ErrorAction SilentlyContinue)
    {
        return $true
    }
    return $false
}

function Remove-WindowsServiceIfItExists($name)
{   
    $exists = Confirm-WindowsServiceExists $name
    if ($exists)
    {    
        sc.exe \\server delete $name
    }       
}

function Start-FileSystemWatcher
{
    # Write-Host "Removing Existing Event Subscribers"
    # Get-EventSubscriber -Force | ForEach-Object {$_.SubscriptionId} | ForEach-Object {Unregister-Event -SubscriptionId $_ }
    # Write-Host "Starting File System Watcher for config map updates"
    # $FileSystemWatcher = New-Object System.IO.FileSystemWatcher
    # $Path = "C:\etc\config\settings"
    # $FileSystemWatcher.Path = $Path
    # $FileSystemWatcher.IncludeSubdirectories = $True
    # $EventName = 'Changed', 'Created', 'Deleted', 'Renamed'
    # $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    # Write-Host $user
    # Write-Host $env:USERPROFILE

    # $Action = {
    #     $fileSystemWatcherStatusPath = "C:\opt\filesystemwatcher.txt"
    #     $secondary = [Environment]::GetFolderPath("MyDocuments") + "\filewatcher.txt"
    #     Write-Host $secondary
    #     $fileSystemWatcherLog = "{0} was  {1} at {2}" -f $Event.SourceEventArgs.FullPath,
    #     $Event.SourceEventArgs.ChangeType,
    #     $Event.TimeGenerated
    #     Write-Host $fileSystemWatcherLog
    #     Add-Content -Path $fileSystemWatcherStatusPath -Value $fileSystemWatcherLog
    #     Set-Content -Path $fileSystemWatcherStatusPath -Value $secondary
    # }

    # $ObjectEventParams = @{
    #     InputObject = $FileSystemWatcher
    #     Action      = $Action
    # }

    # ForEach ($Item in $EventName) {
    #     $ObjectEventParams.EventName = $Item
    #     $ObjectEventParams.SourceIdentifier = "File.$($Item)"
    #     Write-Host  "Starting watcher for Event: $($Item)"
    #     $Null = Register-ObjectEvent  @ObjectEventParams
    # }

    # Get-EventSubscriber -Force 
    Start-Process powershell -NoNewWindow .\filesystemwatcher.ps1
}

#register fluentd as a windows service

function Set-EnvironmentVariables
{
    #set agent config schema version
    $schemaVersionFile = '/etc/config/settings/schema-version'
    if (Test-Path $schemaVersionFile) {
        $schemaVersion = Get-Content $schemaVersionFile | ForEach-Object { $_.TrimEnd() } 
        if ($schemaVersion.GetType().Name -eq 'String') {
            [System.Environment]::SetEnvironmentVariable("AZMON_AGENT_CFG_SCHEMA_VERSION", $schemaVersion, "Process")
            [System.Environment]::SetEnvironmentVariable("AZMON_AGENT_CFG_SCHEMA_VERSION", $schemaVersion, "Machine")
        }
        $env:AZMON_AGENT_CFG_SCHEMA_VERSION
    }

    # run config parser
    ruby /opt/tomlparser.rb
    .\setenv.ps1
}

function Start-Fluent 
{
    #register fluentd as a service and start
    # there is a known issues with win32-service https://github.com/chef/win32-service/issues/70
    fluentd --reg-winsvc i --reg-winsvc-auto-start --winsvc-name fluentdwinaks --reg-winsvc-fluentdopt '-c C:/etc/fluent/fluent.conf -o C:/etc/fluent/fluent.log'

    # Run fluent-bit as a background job. Switch this to a windows service once fluent-bit supports natively running as a windows service
    Start-Job -ScriptBlock { Start-Process -NoNewWindow -FilePath "C:\fluent-bit\bin\fluent-bit.exe" -ArgumentList @("-c", "C:\omsagentwindows\fluent-bit.conf", "-e", "C:\omsagentwindows\out_oms.so") }

    Notepad.exe | Out-Null
}

function Generate-Certificates
{
    Write-Host "Generating Certificates"
    C:\\omsagentwindows\certgenerator\\ConsoleApp1.exe
}

Start-Transcript -Path main.txt
Remove-WindowsServiceIfItExists "fluentdwinaks"
Set-EnvironmentVariables
Start-FileSystemWatcher
Generate-Certificates
Start-Fluent

# List all powershell processes running. This should have main.ps1 and filesystemwatcher.ps1
Get-WmiObject Win32_process | Where-Object {$_.Name -match 'powershell'} | Format-Table -Property Name, CommandLine, ProcessId

#check if fluentd service is running
Get-Service fluentdwinaks




