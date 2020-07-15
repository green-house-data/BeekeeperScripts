PARAM
(
    #the script input variables
    [Parameter(Mandatory = $True)]
    [Alias('BK')]
	[String] $BKServer = "SERVERNAME",

    [Parameter(Mandatory = $False)]
    [Alias('DaysInAdvance')]
	[Int] $NumDaysInAdvance = 0,

    [Parameter(Mandatory = $False)]
    [Alias('WeeksInAdvance')]
	[Int] $NumWeeksInAdvance = 0,

    [Parameter(Mandatory = $False)]
    [Alias('MonthInAdvance')]
	[String] $NextMonth = "N",

    [Parameter(Mandatory = $True)]
    [Alias('OutFolder')]
	[String] $OutputFolder = "C:\Beekeeper"

)

$OutEmailAddresses = @()
$TestEmailAddresses = @()
$BKSchedules = @()
$DayoWeek = (Get-Date).DayofWeek
$SchedYear = Get-Date -Format "yyyy"
$SchedMon = Get-Date -Format "MM"
$CurrentDay = Get-Date -Format "dd"

If(($NumDaysInAdvance -eq 0) -and ($NumWeeksInAdvance -eq 0) -and ($NextMonh = "N"))
  { 
   #Use 2 as default
   $SchedDay = (Get-Date).Adddays(2).Day
   $OutDay = (Get-Date).Adddays(2).DayOfWeek
  }
If($NumDaysInAdvance -ne 0)
  {
   $SchedDay = (Get-Date).Adddays($NumDaysInAdvance).Day
   $SchedMon = (Get-Date).Adddays($NumDaysInAdvance).Month
   $SchedYear = (Get-Date).Adddays($NumDaysInAdvance).Year
   $OutDay = (Get-Date).Adddays($NumDaysInAdvance).DayOfWeek

  }
If($NumWeeksInAdvance -ne 0)
  {
   $NumDaysInAdvance = $NumWeeksInAdvance * 7
   $SchedDay = (Get-Date).Adddays($NumDaysInAdvance).Day
   $SchedMon = (Get-Date).Adddays($NumDaysInAdvance).Month
   $SchedYear = (Get-Date).Adddays($NumDaysInAdvance).Year
   $OutDay = (Get-Date).Adddays($NumDaysInAdvance).DayOfWeek
   $ToDay = (Get-Date).Adddays($NumDaysInAdvance + 7).Day
   $ToMon = (Get-Date).Adddays($NumDaysInAdvance + 7).Month
   $ToYear = (Get-Date).Adddays($NumDaysInAdvance + 7).Year
  }
If($NextMonth -ne "N")
  {
   $SchedDay = "01"
   $SchedMon = (Get-Date).AddMonths(1).Month
   $SchedYear = (Get-Date).AddMonths(1).Year
   $OutDay = (Get-Date -Day 01).AddMonths(1).DayOfWeek
   $ToDay = ((Get-Date -Day 01).AddMonths(1)).AddDays(-1).day
   $ToMon = $SchedMon
   $ToYear = $SchedYear
  }
If(([string]$SchedMon).length -eq 1) 
  {
    $SchedMon = "0" + $SchedMon
  }
If(([string]$SchedDay).length -eq 1) 
  {
    $SchedDay = "0" + $SchedDay
  }
If(([string]$ToMon).length -eq 1) 
  {
    $ToMon = "0" + $ToMon
  }
If(([string]$ToDay).length -eq 1) 
  {
    $ToDay = "0" + $ToDay
  }

$NodeCount = 0
$GroupCount = 1
$MonthName = (Get-Culture).DateTimeFormat.GetMonthName($SchedMon)
$OutLocation = $OutputFolder + "\BKSched.html"
$OutHeaderTitle = "Patching will occur on " + $OutDay + " - " + $MonthName + " " + $SchedDay + ", " + $SchedYear
If($NumDaysInAdvance -ne 0 )
  {
   $OutHeaderTitle = "Patching will occur on " + $OutDay + " - " + $MonthName + " " + $SchedDay + ", " + $SchedYear
  }
If($NumWeeksInAdvance -ne 0  -or $NextMonth -ne "N")
  {
   $OutHeaderTitle = "Patching will occur " +  $SchedMon + "/" + $SchedDay + "/" + $SchedYear + " to: " + $ToMon + "/" + $ToDay + "/" + $ToYear
  }
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
normal;background:#333333'><span style='font-size:13.5pt;color:white'>Beekeeper Patching Schedule Bulletin:</span></p>

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
<table width='520' style='font-size:10.0pt;font-family:"Helvetica",sans-serif'>
<col width='160'>
<col width='200'>
<col width='120'>
<tr><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Patch Window</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Server Group</th><th><span style='font-size:12.0pt;font-family:"Helvetica",sans-serif'>Server</th></span></tr>
"@
$OutHeader | out-file $OutLocation -Force
$NextCheckDate = $OutYear + "-" + $OutMon + "-" + $NextCheckDay
If($NumDayssInAdvance -ne 0 )
  {
   $Schedrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/Schedules?`$filter=(year(PatchDate) eq " + $SchedYear + " and month(PatchDate) eq " + $SchedMon + "and day(PatchDate) eq " + $SchedDay + ")"
  }
If($NumWeeksInAdvance -ne 0  -or $NextMonth -ne "N")
  {
   $Schedrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/Schedules?`$filter=((year(PatchDate) ge " + $SchedYear + " and month(PatchDate) ge " + $SchedMon + " and day(PatchDate) ge " + $SchedDay + ") and (year(PatchDate) le " + $ToYear + " and month(PatchDate) le " + $ToMon + " and day(PatchDate) le " + $ToDay + "))"
  }
$URI_Headers = @{ 'Accept' = 'application/json' }
$Schedresults = Invoke-RestMethod -Uri $SchedrequestUri -UseDefaultCredentials -Headers $URI_Headers
If ($Schedresults -ne $Null)
{
	If ($Schedresults.value.count -gt 0)
	{
		For ($i = 0; $i -lt $Schedresults.value.count; $i++)
		{
          If($Schedresults.value.count -eq 1)
          {
			$M = $Schedresults.value.MaxRunTime
			$NextPatchTime = [DateTime]$Schedresults.value.PatchDate
			$OutStartTime = ($NextPatchTime).ToShortTimeString()
			$OutEndTime = (($NextPatchTime).AddMinutes($M)).ToShortTimeString()
            $OutDate = ($NextPatchTime).ToShortDateString()
			$OutWindow = $OutStartTime + " on " + $OutDate
			$Sched_ClusterID = $Schedresults.value.ScheduleId

          }
          Else
           {
			$M = $Schedresults.value.MaxRunTime[$i]
			$NextPatchTime = [DateTime]$Schedresults.value.PatchDate[$i]
			$OutStartTime = ($NextPatchTime).ToShortTimeString()
			$OutEndTime = (($NextPatchTime).AddMinutes($M)).ToShortTimeString()
            $OutDate = ($NextPatchTime).ToShortDateString()
			$OutWindow = $OutStartTime +  " on " + $OutDate
			$Sched_ClusterID = $Schedresults.value.ScheduleId[$i]
            }
			$Clustersrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/Schedules($Sched_ClusterID)/Clusters"
			$Clusterresults = Invoke-RestMethod -Uri $ClustersrequestUri -UseDefaultCredentials -Headers $URI_Headers
			If ($Clusterresults.value.count -eq 1)
			{
				$Cluster_ID = $Clusterresults.value.ClusterId
				$CR_EmailAddress = $Clusterresults.value.NotificationAddress
				$CR_ClusterName = $Clusterresults.value.ClusterName
				If ($CR_EmailAddress -Match "; ")
				  {
					$TestEmails = ($CR_EmailAddress -Split "; ")
					For ($r = 0; $r -le $TestEmails.Count; $r++)
					{
                        $OutEmailAddresses += $TestEmails[$r]
					}
				}
				Else
				{
					$OutEmailAddresses += ,$CR_EmailAddress
				}
				$ClusterNodesrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=ClusterId eq " + $Cluster_ID
				$ClusterNodesresults = Invoke-RestMethod -Uri $ClusterNodesrequestUri -UseDefaultCredentials -Headers $URI_Headers
                $ClusterNodes = @()
				If ($ClusterNodesresults.value.Count -eq 1)
				{
					$ClusterNodes += ,($ClusterNodesresults.value.NodeName).ToUpper()
				}
				Else
				{
					For ($j = 0; $j -lt $ClusterNodesresults.value.count; $j++)
					{
						$ClusterNodes += ,($ClusterNodesresults.value.NodeName[$j]).ToUpper()
					}
				}
                $Sched_Sort_Time = ([datetime]$NextPatchTime).ToString("yyyy/MM/dd HH:mm:ss")
                $objSchedRecords = New-Object System.Object
                $objSchedRecords | Add-Member -type NoteProperty -Name PatchWindow -Value $OutWindow
                $objSchedRecords | Add-Member -type NoteProperty -Name SortWindow -Value $Sched_Sort_Time
                $objSchedRecords | Add-Member -type NoteProperty -Name ClusterName -Value $CR_ClusterName
                $objSchedRecords | Add-Member -type NoteProperty -Name ClusterNodes -Value $ClusterNodes
                $BKSchedules += $objSchedRecords
			}
			Else
			{
				For ($k = 0; $k -lt $Clusterresults.value.count; $k++)
				{
					$Cluster_ID = $Clusterresults.value.ClusterId[$k]
					$CR_EmailAddress = $Clusterresults.value.NotificationAddress[$k]
					$CR_ClusterName = $Clusterresults.value.ClusterName[$k]
       				If ($CR_EmailAddress -Match "; ")
		     		  {
			     		$TestEmails = ($CR_EmailAddress -Split "; ")
				    	For ($r = 0; $r -le $TestEmails.Count; $r++)
					    {
                         $OutEmailAddresses += $TestEmails[$r]
					    }
				      }
				    Else
			          {
					   $OutEmailAddresses += ,$CR_EmailAddress
				      }					
					$ClusterNodesrequesturi = "http://" + $BKServer + "/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=ClusterId eq " + $Cluster_ID
				 	$ClusterNodesresults = Invoke-RestMethod -Uri $ClusterNodesrequestUri -UseDefaultCredentials -Headers $URI_Headers                    
                    $ClusterNodes = @()
				    If ($ClusterNodesresults.value.Count -eq 1)
			    	{
				    	$ClusterNodes += ,($ClusterNodesresults.value.NodeName).ToUpper()
				    }
				    Else
				    {
				    	Foreach($Cluster_Node in $ClusterNodesresults.value.NodeName)
				    	{
				    		$ClusterNodes += ,($Cluster_Node).ToUpper()
				    	}
			    	}
                $Sched_Sort_Time = ([datetime]$NextPatchTime).ToString("yyyy/MM/dd HH:mm:ss")
                $objSchedRecords = New-Object System.Object
                $objSchedRecords | Add-Member -type NoteProperty -Name PatchWindow -Value $OutWindow
                $objSchedRecords | Add-Member -type NoteProperty -Name SortWindow -Value $Sched_Sort_Time
                $objSchedRecords | Add-Member -type NoteProperty -Name ClusterName -Value $CR_ClusterName
                $objSchedRecords | Add-Member -type NoteProperty -Name ClusterNodes -Value $ClusterNodes
                $BKSchedules += $objSchedRecords
				}
			}
			
		}
	}
}
$SortedRecords = $BKSchedules |Sort SortWindow, ClusterName
Foreach($Record in $SortedRecords)
{			
  If($GroupCount % 2 -eq 1)
    {
	  $ShadeLine = 'No'
	}
  Else
	{
	  $ShadeLine = 'Yes'
	}
  If($Record.ClusterNodes.Count -eq 1)
    {
      If($ShadeLine -eq 'Yes')
		{
		  $Entry = '<tr><td style="background-color:#A7A7A7;">' + $Record.PatchWindow + '</td><td style="background-color:#A7A7A7;">' + $Record.ClusterName + '</td><td style="background-color:#A7A7A7;">' + $Record.ClusterNodes + "</td></tr>"
		}
	  Else
		{
		  $Entry = '<tr><td>' + $Record.PatchWindow + '</td><td>' + $Record.ClusterName + '</td><td>' + $Record.ClusterNodes + "</td></tr>"
		}
	  Add-Content $OutLocation $Entry
      $NodeCount++
    }
  Else
    {
      $SortedNodes = $Record.ClusterNodes | Sort | Get-Unique
      $CheckNode = $SortedNodes[0]
      Foreach($Node in $SortedNodes)
        {
          If($Node -eq $CheckNode)
            {
             If($ShadeLine -eq 'Yes')
	           {
		        $Entry = '<tr><td style="background-color:#A7A7A7;">' + $Record.PatchWindow + '</td><td style="background-color:#A7A7A7;">' + $Record.ClusterName + '</td><td style="background-color:#A7A7A7;">' + $Node + "</td></tr>"
		       }
	         Else
		       {
		        $Entry = '<tr><td>' + $Record.PatchWindow + '</td><td>' + $Record.ClusterName + '</td><td>' + $Node + "</td></tr>"
		       }
	         Add-Content $OutLocation $Entry
            }
          Else
            {
             If($ShadeLine -eq 'Yes')
	           {
		        $Entry = '<tr><td style="background-color:#A7A7A7;"> </td><td style="background-color:#A7A7A7;"> </td><td style="background-color:#A7A7A7;">' + $Node + "</td></tr>"
		       }
	         Else
		       {
		        $Entry = '<tr><td> </td><td> </td><td>' + $Node + "</td></tr>"
		       }
	         Add-Content $OutLocation $Entry
            }
          $NodeCount++
        }
    }
  $GroupCount++
}


$OutEmailAddresses = $OutEmailAddresses|Sort|Get-Unique
$OutGen = "Report Generated: " + (get-date)

$OutFooter = @("
</table>
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
Add-Content $OutLocation $Outfooter
For ($y = 0; $y -lt $OutEmailAddresses.Count; $y++)
{
  If($y -eq 0)
  {
   $ToAddress = $OutEmailAddresses[$y]
  }
  Else
  {
    
   $ToAddress = $ToAddress + "," + $OutEmailAddresses[$y]
  }
}

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
If($NodeCount -gt 0)
{
  $msg = new-object Net.Mail.MailMessage
  $smtp = new-object Net.Mail.SmtpClient($SMTPRelay)
  $msg.From = $SMTPFromAddress
  $msg.To.Add($OutEmailAddresses)
  $msg.subject = "Beekeeper Maintenance Bulletin for " + $OutDay + " - " + $MonthName + " " + $SchedDay + ", " + $SchedYear
  $msg.IsBodyHtml = $True
  $body = [System.IO.File]::ReadAllText($OutLocation)
  $msg.Body = $body
  $smtp.Send($msg)
  $msg.Dispose();
}

