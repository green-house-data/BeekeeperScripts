#==================================================================
#     PreNode Maintenance Task to Live Migrate VMs before patching=
#==================================================================
$ClusterName = "#!clustername!#"
$ClusterNode = "#!nodename!#"

Import-Module FailoverClusters
Import-Module Hyper-V
#======================================
#     Get System Variables            =
#======================================
$URI_Headers = @{ 'Accept' = 'application/json' }
$SettingsRequestURI = "http://localhost/BeekeeperApi/OPAS.svc/SystemVariables"
$SettingResults = Invoke-RestMethod -Uri $SettingsRequestURI -UseDefaultCredentials -Headers $URI_Headers
$MoveTimeout = 180
Foreach($Variable in $SettingResults.value)
{
 If($Variable.Name -eq "Cluster Node Rebalance Resources Timeout")
 {
   $MoveTimeout = $Variable.Value 
 }
}
#======================================
#     Get Nodes in Cluster            =
#======================================
$OtherNodes = (get-clusternode -Cluster $ClusterName | Where-Object { $_.State -eq "Up" -and $_.Name -ne $ClusterNode })
If($OtherNodes.count -eq 1)
{
   $TargetNode = $OtherNodes.Name
}
Else
{
   $Element = $OtherNodes.GetUpperBound(0)
   $TargetNode = $OtherNodes[$Element].Name
}
#======================================
#     Get VMs on Cluster              =
#======================================
$VMs = Get-ClusterGroup -Cluster $ClusterName | ? {$_.GroupType –eq 'VirtualMachine' -and $_.State -eq 'Online'} 
Foreach($VM in $VMs)
{
   If($VM.OwnerNode -eq $ClusterNode)
   {
#================================================
#     Live Migrate VMs to Other Cluster Nodes   =
#================================================
#================================================
      $WarningText = "Pre-Maintenance Live Migrate: " + $VM.Name + " to " + $TargetNode
      Write-Warning $WarningText
      Move-ClusterVirtualMachineRole $VM -Cluster $ClusterName -Node $TargetNode -Wait $MoveTimeout -ErrorAction SilentlyContinue 
     # $Error.Clear()
   }
}
$AfterVMs = Get-ClusterGroup -Cluster $ClusterName | ? {$_.GroupType –eq 'VirtualMachine' -and $_.State -eq 'Online' -and $_.OwnerNode -eq $ClusterNode} 
If($AfterVMs.Count -gt 0)
 {
   Foreach($AfterVM IN $AfterVMs)
   {
     $ErrorText = "Pre-Maintenance Live Migrate: " + $ClusterNode + " VM did not migrate: " + $AfterVM.Name
     Write-Error $ErrorText
   }
 }
Else
 {
   #$Error.Clear()
 }