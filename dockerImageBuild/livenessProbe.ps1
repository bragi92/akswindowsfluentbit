$IsFluentBitRunning = tasklist /fi "imagename eq fluent-bit.exe" /fo "table";

If ($IsFluentBitRunning -like "INFO: No tasks are running which match the specified criteria.") {
    exit 1;
}

exit 0;
