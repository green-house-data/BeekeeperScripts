PARAM
(
   [Parameter(Mandatory = $True)]
   [Alias('DAG')]
   [String]$DAGName = "DAG"
)


Function Get-ExchangeSchemaVersion
{
    $schemaVersionExchange = (Get-ADObject -Identity "CN=ms-Exch-Schema-Version-Pt,CN=schema,CN=configuration,$((Get-ADRootDSE).defaultNamingContext)" -Properties rangeUpper).rangeUpper

    switch ($schemaVersionExchange)
    { 
        14622 { '2010 RTM' }  
        14726 { '2010 SP1' }  
        14732 { '2010 SP2' }  
        14734 { '2010 SP3' }  
        15137 { '2013 RTM' }  
        15254 { '2013 CU1' }  
        15281 { '2013 CU2' }  
        15283 { '2013 CU3' }  
        15292 { '2013 CU4' }  
        15300 { '2013 CU5' }  
        15303 { '2013 CU6' }  
        15312 { '2013 CU7' }
        15317 { '2016 Preview' }
        Default {'2016'}
    }
}


If($DAGName -eq "DAG")
{
  Write-Warning "DAG parameter is blank...stopping execution"
  break
}
Else
{ 
  $BKPreCheckInfo = @()
  $InMaintMode = "No"
  Import-Module ActiveDirectory
  $outVersion = Get-ExchangeSchemaVersion
  If($outVersion.Substring(0,4) -eq "2010")
   {
     Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
   }
  Else
   {
     Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
   }

   $DAGList = Get-DatabaseAvailabilityGroup -Identity $DAGName -Status
   foreach($DAGNode in $DAGList.Servers)
  {
    $Get_DiskInfo = gwmi -query "select * from Win32_LogicalDisk where DriveType=3 and Name = 'C:'" -ComputerName $DAGNode
    If($Get_DiskInfo.FreeSpace -lt 2048000000)
    {
       $LowDisk = "Yes"
    }
    Else
    {
       $LowDisk = "No"
    }
    If($DAGList.ServersInMaintenance.Count -gt 0)
    {
       foreach($Node in $DAGList.ServersInMaintenance)
       {
        If($Node.Name -eq $DAGNode)
        {
           $InMaintMode = "Yes"
        }
       }
    }
    Else
    {
     $InMaintMode = "No"
    }
    $SvcStatus = Get-Service  -ComputerName $DAGNode
    $SCCMAgent = "Not Installed"
    $WinRM = "Disabled"
    foreach($Svc in $SvcStatus)
    {
      If($Svc.DisplayName -eq "SMS Agent Host")
      {
         $SCCMAgent = $Svc.Status
      }
      If($Svc.Name -eq "WinRM")
      {
         $WinRM = $Svc.Status
      }
    }
    If($DAGList.DatabaseAvailabilityGroupIpAddresses.IPAddressToString -eq "255.255.255.255")
    {
       $ClusterNodeStatus = "IPless"
    }
    Else
    {
       $Get_ClusterNode = Get-ClusterNode -Cluster $DAGList.DatabaseAvailabilityGroupIpAddresses.IPAddressToString
       $ClusterNodeStatus = "Down"
       foreach($ClusterNode in $Get_ClusterNode)
       {
          If($ClusterNode.Name -eq $DAGNode)
          { 
             $ClusterNodeStatus = $ClusterNode.State
          }
       }
    }
    $objDAGNodeCheck = New-Object System.Object
    $objDAGNodeCheck | Add-Member -type NoteProperty -Name Name -Value $DAGNode
    $objDAGNodeCheck | Add-Member -type NoteProperty -Name LowDisk -Value $LowDisk
    $objDAGNodeCheck | Add-Member -type NoteProperty -Name MaintMode -Value $InMaintMode
    $objDAGNodeCheck | Add-Member -type NoteProperty -Name SCCMAgent -Value $SCCMAgent
    $objDAGNodeCheck | Add-Member -type NoteProperty -Name WinRM -Value $WinRM
    $objDAGNodeCheck | Add-Member -type NoteProperty -Name ClusterNodeStatus -Value $ClusterNodeStatus
    $BKPreCheckInfo += $objDAGNodeCheck 
  }

  $BKPreCheckInfo |sort Name |FT
}