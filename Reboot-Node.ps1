    $OutTime = Get-Date
    $TargetNode = "#!nodename!#"
    $WarningText = "Rebooting: " + $TargetNode + " at " + $OutTime
    Write-Warning $WarningText
    Restart-Computer $TargetNode -Force
	$Counter = 0
	$vmOnline = $true
	Do
	{
		$PingOut = Test-Connection $TargetNode -ErrorAction SilentlyContinue
        If($PingOut.Count -lt 4)  
		{
			$vmOnline = $false
		}
		$Counter++
		Start-Sleep -s 10
	}
	While (($vmOnline -eq $true) -and ($Counter -ne 90))
    $OutTime = Get-Date
    $WarningText = $TargetNode + " offline at " + $OutTime
    Write-Warning $WarningText
	$Counter = 0
	Do
	{
		Try
		{
			Get-Service -ComputerName $TargetNode | Where-Object { ($_.Name -eq "WinRM") } | Out-Null
			$InitServices = $true
		}
		Catch
		{
			$InitServices = $false
			Start-Sleep -s 10
			$Counter++
		}
	}
	While (($InitServices -ne $true) -and ($Counter -ne 60))
    $OutTime = Get-Date
    $WarningText = $TargetNode + " returns to service at " + $OutTime
    Write-Warning $WarningText
