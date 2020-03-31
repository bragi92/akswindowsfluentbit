#region Build  FileSystemWatcher
$FileSystemWatcher = New-Object  System.IO.FileSystemWatcher
$Path = 'C:\etc\config\settings'
$FileSystemWatcher.Path = $Path
$FileSystemWatcher.IncludeSubdirectories = $True
$EventName = 'Changed', 'Created', 'Deleted', 'Renamed'

$Action = {
    Switch ($Event.SourceEventArgs.ChangeType) {
        'Renamed' {
            $Object = "{0} was  {1} to {2} at {3}" -f $Event.SourceArgs[-1].OldFullPath,
            $Event.SourceEventArgs.ChangeType,
            $Event.SourceArgs[-1].FullPath,
            $Event.TimeGenerated
        }
        Default {
            $Object = "{0} was  {1} at {2}" -f $Event.SourceEventArgs.FullPath,
            $Event.SourceEventArgs.ChangeType,
            $Event.TimeGenerated
        }
    }
    $WriteHostParams = @{
        ForegroundColor = 'Green'
        BackgroundColor = 'Black'
        Object          = $Object
    }
    Write-Host  @WriteHostParams
}

$ObjectEventParams = @{
    InputObject = $FileSystemWatcher
    Action      = $Action
}
ForEach ($Item in  $EventName) {
    $ObjectEventParams.EventName = $Item
    $ObjectEventParams.SourceIdentifier = "File.$($Item)"
    Write-Verbose  "Starting watcher for Event: $($Item)"
    $Null = Register-ObjectEvent  @ObjectEventParams
}