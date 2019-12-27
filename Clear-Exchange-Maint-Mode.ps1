Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
$DAGName = "#!clustername!#"
$DAGList = Get-DatabaseAvailabilityGroup -Identity $DAGName -Status
$MaintCount = 0
 foreach($DAGNode in $DAGList.Servers)
   {
    If($DAGList.ServersInMaintenance.Count -gt 0)
    {
       foreach($Node in $DAGList.ServersInMaintenance)
       {
        If($Node.Name -eq $DAGNode)
        {
		$Server = $Node.Name
        $MaintCount++
		$Msg =  "INFO: " + $Server + " is in Exchange Maintenance Mode!"
		Write-Warning $Msg
		$discoveredServer = Get-ExchangeServer -Identity $Server | Select IsHubTransportServer,IsFrontendTransportServer,AdminDisplayVersion
		$Msg =  "INFO: Remove DAG node from Exchange Maintenance Mode - Reactivating all server components"
		Write-Warning $Msg
		Set-ServerComponentState $server -Component ServerWideOffline -State Active -Requester Maintenance|Out-Null
		if($discoveredServer.IsHubTransportServer -eq $true){
						
			$mailboxserver = Get-MailboxServer -Identity $Server | Select DatabaseAvailabilityGroup
			
			if($mailboxserver.DatabaseAvailabilityGroup -ne $null){
				$Msg = "INFO: Server $server is a member of a Database Availability Group. Resuming the node now."
				Write-Warning $Msg
				$Msg = "INFO: Resuming cluster service"
				Write-Warning $Msg
				Invoke-Command -ComputerName $Server -ArgumentList $Server {Resume-ClusterNode $args[0]} -ErrorAction SilentlyContinue|out-null
				$Msg = "INFO: Activating mailbox databases and policy"
				Write-Warning $Msg
				Set-MailboxServer $Server -DatabaseCopyActivationDisabledAndMoveNow $false|Out-Null
				Set-MailboxServer $Server -DatabaseCopyAutoActivationPolicy Unrestricted|Out-Null
			}
			$Msg = "INFO: Resuming HubTransport Service"
			Write-Warning $Msg
			Set-ServerComponentState –Identity $Server -Component HubTransport -State Active -Requester Maintenance
			$Msg = "INFO: Resuming MSExchangeTransport Service"
			Write-Warning $Msg
			Invoke-Command -ComputerName $Server {Restart-Service MSExchangeTransport} | Out-Null

		}
		#restart FE Transport Services if server is also CAS
		if($discoveredServer.IsFrontendTransportServer -eq $true){
			$Msg = "INFO: Resuming MSExchangeFrontEndTransport Service"
			Write-Warning $Msg
			Invoke-Command -ComputerName $Server {Restart-Service MSExchangeFrontEndTransport} | Out-Null
		}
		$Msg = "INFO: Done! Server $server successfully taken out of Exchange Maintenance Mode."
		Write-Warning $Msg
		$ComponentStates = (Get-ServerComponentstate $Server).LocalStates | ?{$_.State -eq "InActive"}
		if($ComponentStates){
			$Msg = 'ERROR: Not all components are ACTIVE - Run: Get-ServerComponentstate $Server).LocalStates | ?{$_.State -eq "InActive"}' 
			Write-Error $Msg
		}
        }
       }
    }
   }		 
If($MaintCount -eq 0)
   {
    $Msg = "INFO: Zero DAG Nodes were in Exchange Maintenance Mode"
    Write-Warning $Msg
   }

