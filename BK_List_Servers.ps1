"ServerName" | out-file "c:\temp\ListofServers.txt" -Force
$URI_Headers = @{ 'Accept' = 'application/json' }
$ClusterNodessrequesturi = "http://localhost/BeekeeperApi/OPAS.svc/ClusterNodes"
$ClusterNodesresults = Invoke-RestMethod -Uri $ClusterNodessrequesturi -UseDefaultCredentials -Headers $URI_Headers

$AppGroupNodes = $ClusterNodesresults.value.NodeName.ToUpper()

If($ClusterNodesresults.value.count-eq 50)
{
Do {
    $LastNode = $ClusterNodesresults.value.NodeID[49]
    $ClusterNodessrequesturi = "http://localhost/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=(NodeId gt $LastNode)"
    $ClusterNodesresults = Invoke-RestMethod -Uri $ClusterNodessrequesturi -UseDefaultCredentials -Headers $URI_Headers
    $AppGroupNodes += $ClusterNodesresults.value.Nodename.ToUpper()
   } Until ($ClusterNodesresults.value.count-lt 50)
}

$OutNodes = $AppGroupNodes|Sort  | Get-Unique -AsString
$numCount++
foreach($Node in $OutNodes)
{
  Add-Content "c:\temp\ListofServers.txt" $Node
  $numCount++
}

