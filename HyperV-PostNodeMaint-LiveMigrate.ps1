#==================================================================
#     Post Maintenance Task to Live Migrate VMs after patching    =
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
#     Get VMs on Cluster              =
#======================================
$VMs = Get-ClusterGroup -Cluster $ClusterName | ? {$_.GroupType –eq 'VirtualMachine' -and $_.State -eq 'Online'}
Foreach($VM in $VMs)
{
#======================================
#     Get VM Preferred Owner          =
#======================================
  $PreferredOwners = Get-ClusterOwnerNode -Cluster $ClusterName -Group $VM.Name | Where-Object {$_.OwnerNodes -eq $ClusterNode}
  If($PreferredOwners.count -gt 0)
  {
    If($VM.OwnerNode -ne $ClusterNode)
    {
#================================================
#     Live Migrate VMs to Other Cluster Nodes   =
#================================================
      $WarningText = "Post-Maintenance Live Migrate: " + $VM.Name + " to " + $ClusterNode
      Write-Warning $WarningText
      Move-ClusterVirtualMachineRole $VM -Cluster $ClusterName -Node $ClusterNode -Wait $MoveTimeout -ErrorAction SilentlyContinue
    }
  }
}


$AfterVMs = Get-ClusterGroup -Cluster $ClusterName | ? {$_.GroupType –eq 'VirtualMachine' -and $_.State -eq 'Online' -and $_.OwnerNode -eq $ClusterNode} 
If($AfterVMs.Count -gt 0)
 {
   Foreach($AfterVM IN $AfterVMs)
   {
    If($AfterVM.OwnerNode -ne $ClusterNode)
     {
     $ErrorText = "Post-Maintenance Live Migrate: " + $ClusterNode + " VM did not migrate: " + $AfterVM.Name
     Write-Error $ErrorText
     }
   }
 }
 Else
 {
   $Error.Clear()
 }