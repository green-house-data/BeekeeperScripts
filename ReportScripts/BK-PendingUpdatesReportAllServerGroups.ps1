PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('BK')]
	[String] $BKServer = "SERVERNAME",

    [Parameter(Mandatory = $True)]
    [Alias('ToAddress')]
	[String] $SMTPToAddress = "dl@mycompany.com",

    [Parameter(Mandatory = $True)]
    [Alias('OutputLocation')]
	[String] $FileOutputLocation = "C:\Beekeeper"
)

$ClusterArray = @()
$Schedrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/Clusters?$orderby=ClusterName"
$URI_Headers = @{ 'Accept' = 'application/json' }
$Schedresults = Invoke-RestMethod -Uri $SchedrequestUri -UseDefaultCredentials -Headers $URI_Headers
foreach($Schedule in $Schedresults.value)
{
 $CLusterArray += ,$Schedule.ClusterName
}
$numCount = 0
$OutHeader = @"
<html><head></head><body>
<style>
table { 
    border-collapse: collapse;
}
td, th { 
    border: 1px solid #ddd;
    padding: 8px;
}
th {
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: center;
    background-color: #EBECF0;
    color: black;
}
</style>
<p > </p>
<p class=MsoNormal style='margin-bottom:0in;margin-bottom:.0001pt;line-height:
normal;background:#333333'><span style='font-size:13.5pt;color:white'>Beekeeper
Pending Software Updates Report </span></p>

<div style='border:none;border-bottom:solid #DDDDDD 1.0pt;padding:0in 0in 4.0pt 0in'>
<p > </p>
<p class=MsoNormal style='margin-top:7.5pt;margin-right:0in;margin-bottom:7.5pt;
margin-left:0in;line-height:normal;border:none;padding:0in'><span
style='font-size:13.5pt;color:#0078D4'> </span></p
</div>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>HTML TABLE</title>
</head><body>

<table width='1065' style=$clk'font-size:10.0pt;font-family:"Helvetica",sans-serif'>
<col width='140'>
<col width='125'>
<col width='800'>
<tr><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Server</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Article ID</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Description</th></span></tr>
"@
$OutHeader | out-file "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" -Force
$URI_Headers = @{ 'Accept' = 'application/json' }
$ItemCount = 0
Foreach($Cluster in $ClusterArray)
{
$ClName = $Cluster
$Clustersrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/Clusters?`$filter=ClusterName eq '" + $ClName + "'"
$Clustersresults = Invoke-RestMethod -Uri $ClustersrequestUri -UseDefaultCredentials -Headers $URI_Headers

   $Entry = '<tr><td> </td><td>   </td><td>   </td></tr>'
   Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry
   $Entry = '<tr><td  colspan="3" style="background-color:#333333; font-size: 11.5pt;color:white"><strong>' + $Cluster + '</strong></td></tr>'
   Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry

$numCount++

If ($Clustersresults.value.Count -gt 0)
{
   If($Clustersresults.value.Count -eq 1)
   {  
      If($Clustersresults.value.ClusterType -eq "Application Group")
      {   
         $ClusterID = $Clustersresults.value.ClusterId
         $ClusterNodessrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=ClusterId eq " + $ClusterID
         $ClusterNodesresults = Invoke-RestMethod -Uri $ClusterNodessrequesturi -UseDefaultCredentials -Headers $URI_Headers
         $AppGroupNodes = $ClusterNodesresults.value |Sort NodeName
         foreach($Node in $AppGroupNodes)
         {
           $Updates = Get-WmiObject -ComputerName $Node.NodeName -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" -ErrorAction SilentlyContinue|Select -Property PSComputerName, Name, ArticleID
           If($Updates.Count -eq 0)
           {
                 $Entry = '<tr><td>' + $Node.NodeName.ToUpper() + '</td><td>   </td><td>No Pending Updates</td></tr>'
              Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry
              $numCount++
              $ItemCount++
           }
           Else
           { 
           $numCount++
           $PrevNode = $null
           $NodeName = $Node.NodeName
           foreach($Update in $Updates)
           { 

		         $Entry = '<tr><td>' + $NodeName.ToUpper() + '</td><td>' + $Update.ArticleID + '</td><td>' + $Update.Name + '</td></tr>'
               If($PrevNode -eq $null)
                {
                 $NodeName = "   "
                }
               Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry
               $ItemCount++
           }
          }

         }
      }
      If($Clustersresults.value.ClusterType -eq "Windows Failover Cluster" -or $Clustersresults.value.ClusterType -eq "SQL Availability Group")
      {
        import-module failoverclusters
        $WFC = Get-ClusterNode -Cluster $ClName 
        foreach($node in $WFC)
        {
           $Updates = Get-WmiObject -ComputerName $Node.Name -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" -ErrorAction SilentlyContinue|Select -Property PSComputerName, Name, ArticleID
           If($Updates.Count -eq 0)
           {
              $Entry = '<tr><td>' + $Node.Name.ToUpper() + '</td><td>   </td><td>No Pending Updates</td></tr>'
              Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry
              $numCount++
              $ItemCount++
           }
           Else
           { 
           $PrevNode = $null
           $NodeName = $Node.Name
           foreach($Update in $Updates)
           { 
               $Entry = '<tr><td>' + $NodeName.ToUpper() + '</td><td>' + $Update.ArticleID + '</td><td>' + $Update.Name + '</td></tr>'
               If($PrevNode -eq $null)
                {
                 $NodeName = "   "
                }
               Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry
               $ItemCount++
            }
           }
           $numCount++
        } 
        }   
      }
      If($Clustersresults.value.ClusterType -eq "Exchange DAG Cluster")
      {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn 
        $DAG = Get-DatabaseAvailabilityGroup $Clustersresults.value.ClusterName
        $DAGout = $DAG.Servers |Sort-Object Name
        foreach ($Server in $DAGout)
        {
           $Updates = Get-WmiObject -ComputerName $Server.Name -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" -ErrorAction SilentlyContinue|Select -Property PSComputerName, Name, ArticleID
           If($Updates.Count -eq 0)
           {
              $Entry = '<tr><td>' + $Server.Name.ToUpper() + '</td><td>   </td><td>No Pending Updates</td></tr>'
              Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry
              #$numCount++
              $ItemCount++
           }
           Else
           { 
           $PrevNode = $null
           $NodeName = $Server.Name
           foreach($Update in $Updates)
           { 

	           $Entry = '<tr><td>' + $NodeName.ToUpper() + '</td><td>' + $Update.ArticleID + '</td><td>' + $Update.Name + '</td></tr>'
               If($PrevNode -eq $null)
                {
                 $NodeName = "   "
                }
               Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Entry
               $ItemCount++
            }
           }
           $numCount++
        } 
      }
   }
# }
}
$OutGen = "Report Generated: " + (get-date)
$OutFooter = @("
</table>
<p style='margin-bottom:8.0pt'><span '><u2:p>&nbsp;</u2:p></span></p>
<p class=MsoNormal><span style='mso-spacerun:yes'>    </span><span
style='mso-spacerun:yes'> </span><span style='mso-no-proof:yes'>
<p style='margin-bottom:12.0pt'><span style='font-size:10.0pt;font-family:Consolas;
mso-bidi-font-family:Consolas;color:#404040'><span style='mso-spacerun:yes'>  
</span>$OutGen<u2:p></u2:p><o:p></o:p></span></p>
<span style='font-size:10.0pt;font-family:Consolas;
mso-bidi-font-family:Consolas;color:#404040'><span style='mso-spacerun:yes'>  
</span><A HREF='http://www.greenhousedata.com/'>Green House Data</A>
</div>

</body>

</html>		
		
	")
Add-Content "$($FileOutputLocation)\BKPendingSoftwareUpdates.html" $Outfooter
$URI_Headers = @{ 'Accept' = 'application/json' }
$SettingsRequestURI = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/SystemVariables"
$SettingResults = Invoke-RestMethod -Uri $SettingsRequestURI -UseDefaultCredentials -Headers $URI_Headers
Foreach($Variable in $SettingResults.value)
{
 If($Variable.Name -eq "SMTP Endpoint")
 {
   $SMTPRelay = $Variable.Value 
 }
 If($Variable.Name -eq "SMTP Send As")
 {
   $SMTPFromAddress = $Variable.Value 
 }
}
If($ItemCount -gt 0)
{
  $msg = new-object Net.Mail.MailMessage
  $smtp = new-object Net.Mail.SmtpClient($SMTPRelay)
  $msg.From = $SMTPFromAddress
  $msg.To.Add($SMTPToAddress)
  $msg.subject = "Beekeeper: Pending Software Updates - All Devices"
  $msg.IsBodyHtml = $True
  $body = [System.IO.File]::ReadAllText("$($FileOutputLocation)\BKPendingSoftwareUpdates.html")
  $msg.Body = $body
  $smtp.Send($msg)
  $msg.Dispose();
}


