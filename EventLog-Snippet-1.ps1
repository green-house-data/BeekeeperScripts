New-EventLog -LogName "Application" -Source "Beekeeper" -ComputerName JFHLABBK01 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

Write-EventLog -LogName "Application" -Source "Beekeeper" -ComputerName JFHLABBK01 -EntryType Information -EventId 101 -Message "New Event" -Category 0 
