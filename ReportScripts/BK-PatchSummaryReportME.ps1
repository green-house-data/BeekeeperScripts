PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('BK')]
	[String] $BKServer = "SERVERNAME",

    [Parameter(Mandatory = $True)]
    [Alias('OutputLocation')]
	[String] $FileOutputLocation = "C:\Beekeeper"
)
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
$CurrYear = Get-Date -Format "yyyy"
$CurrMon = Get-Date -Format "MM"
$CurrDay = Get-Date -Format "dd"
$MonthName = (Get-Culture).DateTimeFormat.GetMonthName($CurrMon)
$FromDate = (Get-Date).AddDays(-2)
$FromYear = $FromDate.Year
$FromMonth = $FromDate.Month
$FromDay = "01"

$DayName = (Get-Date).DayOfWeek
$OutHeaderTitle = "Beekeeper Patching occurred on " + $DayName + " - " + $MonthName + " " + $CurrDay + ", " + $CurrYear
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
<p class=MsoNormal style='margin-bottom:0in;margin-bottom:.0001pt;line-height:
normal;background:#333333'><span style='font-size:13.5pt;color:white'>Beekeeper Month End Patching Report</span></p>

<div style='border:none;border-bottom:solid #DDDDDD 1.0pt;padding:0in 0in 4.0pt 0in'>

<p class=MsoNormal style='margin-top:7.5pt;margin-right:0in;margin-bottom:7.5pt;
margin-left:0in;line-height:normal;border:none;padding:0in'><span
style='font-size:13.5pt;color:#0078D4'> </span></p

</div>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>HTML TABLE</title>
</head><body>
<table width='1640' style='font-size:10.0pt;font-family:"Helvetica",sans-serif'>
<col width='110'>
<col width='75'>
<col width='95'>
<col width='215'>
<col width='250'>
<col width='70'>
<col width='250'>
<col width='70'>
<col width='500'>
<tr><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Server</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Uptime</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Status</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>End Time</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Installed Patches</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Installed Count</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Failed Patches</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Failed Count</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Error Message</th></span></tr>
"@

$ItemCount = 1
$CountFlag = "N"
$OutLocation = $FileOutputLocation + "\BKPatchResultsME.html"
$OutHeader | out-file $OutLocation -Force
$URI_Headers = @{ 'Accept' = 'application/json' }
$PatchingRequestURI = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/PatchRecords?`$filter=(year(EndTime) ge " + $FromYear + " and month(EndTime) ge " + $FromMonth + " and day(EndTime) ge " + $FromDay + ")"
$PatchingResults = Invoke-RestMethod -Uri $PatchingRequestURI -UseDefaultCredentials -Headers $URI_Headers
$BKPatchRecords = @()
Do
{
foreach($PatchRecord in $PatchingResults.value)
{

  If($PatchRecord.'odata.type' -eq "OPASSvc.ClusterPatchRecord")
   {
      $Patch_Cluster_ID = $PatchRecord.ClusterID
      $Clustersrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/Clusters?`$filter=ClusterId eq " + $Patch_Cluster_ID 
	  $Clusterresults = Invoke-RestMethod -Uri $ClustersrequestUri -UseDefaultCredentials -Headers $URI_Headers
      $Patch_ToAddress = $Clusterresults.value.NotificationAddress
   }
  If($PatchRecord.'odata.type' -eq "OPASSvc.NodePatchRecord")
   {
     $NodeRequestURI = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=NodeId eq $($PatchRecord.NodeId)"
     $NodeResults = Invoke-RestMethod -Uri $NodeRequestURI -UseDefaultCredentials -Headers $URI_Headers
     $Patch_Node = $NodeResults.value.NodeName
     $Patch_Status = $PatchRecord.Status
     $Patch_Time = ([datetime]$PatchRecord.EndTime).ToString("HH:mm:ss on MMMM dd, yyyy")
     $Patch_Sort_Time = ([datetime]$PatchRecord.EndTime).ToString("yyyy/MM/dd HH:mm:ss")
     $Patch_InstalledList = $PatchRecord.InstalledPatchList
     $Patch_InstalledCount = $PatchRecord.PatchesInstalledCount
     $Patch_FailedList = $PatchRecord.FailedPatchList
     $Patch_FailedCount = $PatchRecord.PatchesFailedCount
     $Patch_Fail_Message = ""
     $Error.Clear()
     $GetNode = Get-CimInstance -ClassName win32_operatingsystem -ComputerName $Patch_Node -ErrorAction SilentlyContinue
     If($Error.Count -eq 0)
       {
        $SinceBoot  = (Get-Date) - $GetNode.lastBootupTime
        $UpTime =  "{0:n3}" -f ($SinceBoot.TotalHours) + " hrs"
       }
     Else
       {
        $UpTime =  "Unknown"
       }

     If($PatchRecord.Status -ne "Succeeded")
      {
        $EventRequestURI = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/Events?`$filter=(NodePatchRecordId eq $($PatchRecord.RecordId)) and (Severity eq 'Critical')"
        $EventResults = Invoke-RestMethod -Uri $EventRequestURI -UseDefaultCredentials -Headers $URI_Headers
        $Patch_Fail_Message = $EventResults.value.Message 
      }


      $objPatchRecords = New-Object System.Object
      $objPatchRecords | Add-Member -type NoteProperty -Name Node -Value $Patch_Node
      $objPatchRecords | Add-Member -type NoteProperty -Name UpTime -Value $UpTime
      $objPatchRecords | Add-Member -type NoteProperty -Name Status -Value $Patch_Status
      $objPatchRecords | Add-Member -type NoteProperty -Name EndTime -Value $Patch_Time
      $objPatchRecords | Add-Member -type NoteProperty -Name SortTime -Value $Patch_Sort_Time
      $objPatchRecords | Add-Member -type NoteProperty -Name InstalledList -Value $Patch_InstalledList
      $objPatchRecords | Add-Member -type NoteProperty -Name InstalledCount -Value $Patch_InstalledCount
      $objPatchRecords | Add-Member -type NoteProperty -Name FailedList -Value $Patch_FailedList
      $objPatchRecords | Add-Member -type NoteProperty -Name FailedCount -Value $Patch_FailedCount
      $objPatchRecords | Add-Member -type NoteProperty -Name Message -Value $Patch_Fail_Message
      $objPatchRecords | Add-Member -type NoteProperty -Name ToAddress -Value $Patch_ToAddress
      $BKPatchRecords += $objPatchRecords

   }
}
If ($PatchingResults.value.count -eq 50)
 {
   $PatchingRequestURI = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/PatchRecords?`$filter=((year(EndTime) eq " + $CurrYear + " and month(EndTime) eq " + $CurrMon + " and day(EndTime) le " + $CurrDay + ") and (RecordId gt $($PatchRecord.RecordId)))"
   $PatchingResults = Invoke-RestMethod -Uri $PatchingRequestURI -UseDefaultCredentials -Headers $URI_Headers
 }
Else
 {
  $CountFlag = "Y"
 }
}
While($CountFlag -eq "N")
$SortedRecords = $BKPatchRecords | sort SortTime
Foreach($Record in $SortedRecords)
  {


		If ($Record.Status -eq "Succeeded")
         {
           $Entry = '<tr><td>' + $Record.Node + '</td><td  align="center">' + $Record.UpTime + '</td><td>' + $Record.Status + '</td><td align="center">' + $Record.EndTime + '</td><td>' + $Record.InstalledList + '</td><td align="right">' + $Record.InstalledCount + '</td><td align="right">' + $Record.FailedList + '</td><td align="right">' + $Record.FailedCount + '</td><td>' + $Record.Message + '</td></tr>'
         }
        Else
         {
           $Entry = '<tr><td span style="color:IndianRed;" align="center">' + $Record.Node + '</td><td span style="color:IndianRed;" align="center">' + $Record.UpTime + '</td><td span style="color:IndianRed;" align="center">' + $Record.Status + '</td><td span style="color:IndianRed;" align="center">' + $Record.EndTime + '</td><td span style="color:IndianRed;" align="center">' + $Record.InstalledList + '</td><td  span style="color:IndianRed;" align="right">' + $Record.InstalledCount + '</td><td span style="color:IndianRed;">' + $Record.FailedList + '</td><td span style="color:IndianRed;" align="right">' + $Record.FailedCount + '</td><td span style="color:IndianRed;" align="center">' + $Record.Message + '</td></tr>'
         }

     Add-Content $OutLocation $Entry
     $ItemCount++
     }
$OutGen = "Report Generated: " + (get-date)

$OutEmailAddresses = @()
Foreach($Record in $SortedRecords){
				If ($Record.ToAddress -Match "; ")
				{
					$TestEmails = ($Record.ToAddress -Split "; ")
					For ($r = 0; $r -le $TestEmails.Count; $r++)
					{
						$strFound = "N"
						For ($s = 0; $s -le $OutEmailAddresses.Count; $s++)
						{
							
							If ($OutEmailAddresses[$s] -eq $TestEmails[$r])
							{
								$strFound = "Y"
							}
						}
						If ($strFound -eq "N")
						{
							$OutEmailAddresses += ,$TestEmails[$r]
						}
					}
				}
				Else
				{
					If ($OutEmailAddresses.Count -gt 0)
					{
						$strFound = "N"
						For ($s = 0; $s -le $OutEmailAddresses.Count; $s++)
						{
							If ($OutEmailAddresses[$s]-eq $Record.ToAddress)
							{
								$strFound = "Y"
							}
						}
						If ($strFound -eq "N")
						{
							$OutEmailAddresses += ,$Record.ToAddress
						}
					}
					Else
					{
						$OutEmailAddresses += ,$Record.ToAddress
					}
				}
}

$OutFooter = @("
</table>
<p style='margin-bottom:12.0pt'><span style='font-size:10.0pt;font-family:Consolas;
mso-bidi-font-family:Consolas;color:#404040'><span style='mso-spacerun:yes'>  
</span>$OutGen<u2:p></u2:p><o:p></o:p></span></p>
<span style='font-size:10.0pt;font-family:Consolas;
mso-bidi-font-family:Consolas;color:#404040'><span style='mso-spacerun:yes'>  
</span>
<A HREF='http://www.greenhousedata.com/'>Green House Data</A>
</div>
</body>
</html>		
	")
Add-Content $OutLocation $Outfooter
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
If (($ItemCount -gt 0) )
{
  $smtpServer = $SMTPRelay
  $msg = new-object Net.Mail.MailMessage
  $smtp = new-object Net.Mail.SmtpClient($SMTPRelay)
  $msg.From = $SMTPFromAddress
  $msg.To.Add($OutEmailAddresses)
  $msg.subject = "Beekeeper: Month End Patching Summary"
  $msg.IsBodyHtml = $True
  $body = [System.IO.File]::ReadAllText($OutLocation)
  $msg.Body = $body
  $smtp.Send($msg)
  $msg.Dispose();

}

