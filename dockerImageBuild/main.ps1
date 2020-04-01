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
    Write-Host "Removing Existing Event Subscribers"
    Get-EventSubscriber -Force | ForEach-Object {$_.SubscriptionId} | ForEach-Object {Unregister-Event -SubscriptionId $_ }
    Write-Host "Starting File System Watcher for config map updates"
    $FileSystemWatcher = New-Object System.IO.FileSystemWatcher
    $Path = 'C:\etc\config\settings'
    $FileSystemWatcher.Path = $Path
    $FileSystemWatcher.IncludeSubdirectories = $True
    $EventName = 'Changed', 'Created', 'Deleted', 'Renamed'
    $fileSystemWatcherStatusPath = 'C:\opt\filesystemwatcher.txt'

    $Action = {
        $fileSystemWatcherLog = "{0} was  {1} at {2}" -f $Event.SourceEventArgs.FullPath,
        $Event.SourceEventArgs.ChangeType,
        $Event.TimeGenerated
        Add-Content -Path $fileSystemWatcherStatusPath -Value $fileSystemWatcherLog
    }

    $ObjectEventParams = @{
        InputObject = $FileSystemWatcher
        Action      = $Action
    }

    ForEach ($Item in $EventName) {
        $ObjectEventParams.EventName = $Item
        $ObjectEventParams.SourceIdentifier = "File.$($Item)"
        Write-Verbose  "Starting watcher for Event: $($Item)"
        $Null = Register-ObjectEvent  @ObjectEventParams
    }
}

Confirm-WindowsServiceExists "fluentdwinaks"
Remove-WindowsServiceIfItExists "fluentdwinaks"
#register fluentd as a windows service

#set agent config schema version
$schemaVersionFile = '/etc/config/settings/schema-version'
if (Test-Path $schemaVersionFile)
{
    $schemaVersion = Get-Content $file  | ForEach-Object {$_.TrimEnd()} 
    if ($schemaVersion.GetType().Name -eq 'String')
    {
        [System.Environment]::SetEnvironmentVariable("AZMON_AGENT_CFG_SCHEMA_VERSION", $schemaVersion, "Process")
        [System.Environment]::SetEnvironmentVariable("AZMON_AGENT_CFG_SCHEMA_VERSION", $schemaVersion, "Machine")
    }
    $env:AZMON_AGENT_CFG_SCHEMA_VERSION
}

# run config parser
ruby .\tomlparser.rb

#register fluentd as a service and start
fluentd --reg-winsvc i --reg-winsvc-auto-start --winsvc-name fluentdwinaks --reg-winsvc-fluentdopt '-c C:/etc/fluent/fluent.conf -o C:/opt/td-agent/td-agent.log'

# Run fluent-bit as a background job. Switch this to a windows service once fluent-bit supports natively running as a windows service
Start-Job -ScriptBlock { Start-Process -NoNewWindow -FilePath "C:\fluent-bit\bin\fluent-bit.exe" -ArgumentList @("-c", "C:\omsagentwindows\fluent-bit.conf", "-e", "C:\omsagentwindows\out_oms.so") }

Notepad.exe | Out-Null