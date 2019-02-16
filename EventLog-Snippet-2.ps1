$NodeName = "#!nodename!#"
########################################################
## Events vary depending on vailidation task phase: ##
## Manually set the $EventID variable and set the ##
## PowerShell script in Beekeeper to that name. ##
## 100 = On Node Start ##
## 101 = Pre Reboot ##
## 102 = Post Reboot ##
## 103 = On Node End ##
## ##
## 200 = Node Failure ##
## ##
########################################################
$EventID = 100
New-EventLog -LogName "Application" -Source "Beekeeper" -ComputerName $NodeName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
If($EventID -eq 100)
{
$EventMsg = "Beekeeper execution job began."
$EventType = "Information"
}
If($EventID -eq 101)
{
$EventMsg = "Beekeeper reboot triggered."
$EventType = "Information"
}
If($EventID -eq 102)
{
$EventMsg = "Beekeeper return from reboot"
$EventType = "Information"
}
If($EventID -eq 103)
{
$EventMsg = "Beekeeper execution job completed successfully."
$EventType = "Information"
}
 
If($EventID -eq 200)
{
$EventMsg = "Beekeeper execution job failed"
$EventType = "Error"
}
 
Write-EventLog -LogName "Application" -Source "Beekeeper" -ComputerName $NodeName -EntryType $EventType -EventId $EventID -Message $EventMsg -Category 0 
