$desktop = "$env:USERPROFILE\Desktop"

# create watcher
$watcher = New-Object IO.FileSystemWatcher $desktop, "*.lnk"
$watcher.EnableRaisingEvents = $true

# handle event
Register-ObjectEvent $watcher Created -Action {
    Start-Sleep -Milliseconds 500  # let file finish writing
    try {
        Remove-Item $Event.SourceEventArgs.FullPath -Force -ErrorAction SilentlyContinue
    } catch {
        # ignore errors
    }
}

# block here forever, only wakes on events
Wait-Event
