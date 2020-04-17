# $IsFluentBitRunning = tasklist /fi "imagename eq fluent-bit.exe" /fo "table"
# tasklist
# [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# $IsFluentBitRunning

# If ($IsFluentBitRunning -like "INFO: No tasks are running which match the specified criteria.") {
#     Write-Host "Fluent-bit process NOT running"
#     exit 1
# }
# else {
#     Write-Host "Fluent-bit process IS running"
# }

# if (Test-Path "C:\etc\omsagentwindows\filesystemwatcher.txt") {
#     Write-Host "Config Map UPDATED since container start"
#     exit 1
# }
# else {
#     Write-Host "Config Map NOT UPDATED since start"
# }

# $ISFluentdRunning = Get-Service fluentdwinaks -ErrorAction SilentlyContinue

# If ($ISFluentdRunning) {
#     Write-Host "Fluentd service IS running"
# }
# else {
#     Write-Host "Fluentd service NOT running"
#     exit 1
# }

exit 0