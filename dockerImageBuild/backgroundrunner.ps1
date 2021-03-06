Write-Host "First Generating the certificates"

.\omsagentwindows\ConsoleApp1.exe

Write-Host "Hostname is $Env:CI_HOSTNAME"

Write-Host "Starting fluent bit for windows in the background..."

#C:\fluent-bit\bin\fluent-bit.exe -c "C:\omsagentwindows\fluent-bit.conf" -e "C:\omsagentwindows\out_oms.so"

Start-Job -ScriptBlock { Start-Process -NoNewWindow -FilePath "C:\fluent-bit\bin\fluent-bit.exe" -ArgumentList @("-c", "C:\omsagentwindows\fluent-bit.conf", "-e", "C:\omsagentwindows\out_oms.so") }

Notepad.exe | Out-Null

#For(;;) {
#infinte loop so that the container keeps running!
#also causes 1 core usage even though its doing nothing!
#}
