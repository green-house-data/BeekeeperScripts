Function Check-SCCM-Agent-Service([string]$NodeName){
    $SvcStatus = Get-Service "SMS Agent Host" -ComputerName $NodeName  
    $WarningText = $NodeName + " SCCM Agent Status: " + $SvcStatus.Status
    Write-Warning $WarningText
	If ($SvcStatus.Status -ne "Running")
	{
		Get-Service "SMS Agent Host" -ComputerName $NodeName | Restart-Service | Out-Null
        $WarningText = $NodeName + " SCCM Agent Started"
        Write-Warning $WarningText
	}
}

$ClName = "#!clustername!#"
$URI_Headers = @{ 'Accept' = 'application/json' }
$Clustersrequesturi = "http://localhost/BeekeeperApi/OPAS.svc/Clusters?`$filter=ClusterName eq '" + $ClName + "'"
$Clustersresults = Invoke-RestMethod -Uri $ClustersrequestUri -UseDefaultCredentials -Headers $URI_Headers
If ($Clustersresults.value.Count -gt 0)
{
   If($Clustersresults.value.Count -eq 1)
   {  
      If($Clustersresults.value.ClusterType -eq "Application Group")
      {  
         $ClusterID = $Clustersresults.value.ClusterId
         $ClusterNodesrequesturi = "http://localhost/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=ClusterId eq " + $ClusterID
         $ClusterNodesresults = Invoke-RestMethod -Uri $ClusterNodesrequestUri -UseDefaultCredentials -Headers $URI_Headers
         foreach($node in $ClusterNodesresults.value)
         {
          Check-SCCM-Agent-Service -Nodename $node.NodeName
         }
      }
      If($Clustersresults.value.ClusterType -eq "Windows Failover Cluster")
      {
        $WFC = Get-ClusterNode -Cluster $Clustersresults.value.ClusterName
        foreach($node in $WFC)
        {
          Check-SCCM-Agent-Service -NodeName $node.Name
        }   
      }
      If($Clustersresults.value.ClusterType -eq "Exchange DAG Cluster")
      {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn 
        $DAG = Get-DatabaseAvailabilityGroup $Clustersresults.value.ClusterName
        foreach ($Server in $DAG.Servers)
        {
         Check-SCCM-Agent-Service -NodeName $Server.Name
        } 
      }

   }
   Else
   {
    foreach($Cl in $Clustersresults.value)
    { 
      If($Cl.ClusterName -eq $ClName)
      {

       If($Cl.ClusterType -eq "Application Group")
       {
         $ClusterID = $Cl.ClusterId
         $ClusterNodesrequesturi = "http://localhost/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=ClusterId eq " + $ClusterID
         $ClusterNodesresults = Invoke-RestMethod -Uri $ClusterNodesrequestUri -UseDefaultCredentials -Headers $URI_Headers
         foreach($node in $ClusterNodesresults.value)
         {
          Check-SCCM-Agent-Service -NodeName $node.NodeName
         }
       }
      
      If($Cl.ClusterType -eq "Windows Failover Cluster")
      {
        $WFC = Get-ClusterNode -Cluster $Cl.ClusterName
        foreach($node in $WFC)
        {
         Check-SCCM-Agent-Service -NodeName $node.NodeName
        }   
      }
      If($Cl.ClusterType -eq "Exchange DAG Cluster")
      {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn 
        $DAG = Get-DatabaseAvailabilityGroup $Cl.ClusterName
        foreach ($Server in $DAG.Servers)
        {
         Check-SCCM-Agent-Service -NodeName $Server.Name
        } 
      }
     }
    }
   }
}