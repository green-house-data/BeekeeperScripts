function Get-PatchStatus
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]$EvalState,
		[parameter(Mandatory = $true)]
		[string]$ComplyState
	)
	$EvaluationStates = @{
		"23"	   = "WaitForOrchestration";
		"22"	   = "WaitPresModeOff";
		"21"	   = "WaitingRetry";
		"20"	   = "PendingUpdate";
		"19"	   = "PendingUserLogoff";
		"18"	   = "WaitUserReconnect";
		"17"	   = "WaitJobUserLogon";
		"16"	   = "WaitUserLogoff";
		"15"	   = "WaitUserLogon";
		"14"	   = "WaitServiceWindow";
		"13"	   = "Error";
		"12"	   = "InstallComplete";
		"11"	   = "Verifying";
		"10"	   = "WaitReboot";
		"9"	       = "PendingHardReboot";
		"8"	       = "PendingSoftReboot";
		"7"	       = "Installing";
		"6"	       = "WaitInstall";
		"5"	       = "Downloading";
		"4"	       = "PreDownload";
		"3"	       = "Detecting";
		"2"	       = "Submitted";
		"1"	       = "Available";
		"0"	       = "None";
	}
	$EvalState = $EvaluationStates.Get_Item("$EvalState")
	
	$ComplianceStates = @{
		"0"  = "NotPresent";
		"1"  = "Present";
		"2"  = "PresenceUnknown/NotApplicable";
		"3"	 = "EvaluationError";
		"4"  = "NotEvaluated";
		"5"	 = "NotUpdated";
		"6"	 = "NotConfigured";
	}
	$ComplyState = $ComplianceStates.Get_Item("$ComplyState")
	
	return [pscustomobject]@{
		"EvaluationState"  = $EvalState
		"ComplianceState"  = $ComplyState
	}
}
$FromYear = Get-Date -Format "yyyy"
$FromMon = Get-Date -Format "MM"
$FromDay = Get-Date -Format "dd"
$URI_Headers = @{ 'Accept' = 'application/json' }
$ExecutionJobsRequestURI = "http://localhost/BeekeeperApi/OPAS.svc/PatchRecords?`$filter=Status eq 'Running'"
$RunningJobsResults = Invoke-RestMethod -Uri $ExecutionJobsRequestURI -UseDefaultCredentials -Headers $URI_Headers
If($RunningJobsResults.value.Count -gt 0)
{
 Write-Host "Current Beekeeper Execution Jobs:" -ForegroundColor Yellow
 Write-Host " "
 Foreach($Record in $RunningJobsResults.Value)
 {
  If($Record.'odata.type' -eq "OPASSvc.ClusterPatchRecord")
  {
    $Clustersrequesturi = "http://localhost/BeekeeperApi/OPAS.svc/Clusters?`$filter=ClusterId eq " + $Record.ClusterId
	$Clusterresults = Invoke-RestMethod -Uri $ClustersrequestUri -UseDefaultCredentials -Headers $URI_Headers
    Write-Host " Group currently Executing: "  $Clusterresults.value.ClusterName " Node count: " $Record.NodeCount -ForegroundColor Cyan
  }
  If($Record.'odata.type' -eq "OPASSvc.NodePatchRecord")
  {
    $NodeRequestURI = "http://localhost/BeekeeperApi/OPAS.svc/ClusterNodes?`$filter=NodeId eq $($Record.NodeId)"
    $NodeResults = Invoke-RestMethod -Uri $NodeRequestURI -UseDefaultCredentials -Headers $URI_Headers
    Write-Host "    On Node: "  $NodeResults.value.NodeName -ForegroundColor Green
    $EventRequestURI = "http://localhost/BeekeeperApi/OPAS.svc/Events?`$filter=(NodePatchRecordId eq $($Record.RecordId))"
    $EventResults = Invoke-RestMethod -Uri $EventRequestURI -UseDefaultCredentials -Headers $URI_Headers
    $Job_Messages = $EventResults.value
    Foreach($Msg in $Job_Messages)
    {
      Write-Host "     " ([datetime]$Msg.DateTime).ToString("yyyy/MM/dd HH:mm:ss") $Msg.Message 
    }
    $CIMSession = New-CimSession -ComputerName $NodeResults.value.NodeName
    $CurrentStatus = Get-CimInstance -CimSession $CIMSession -ClassName CCM_SoftwareUpdate -Namespace root\CCM\ClientSDK
    $Output = @()
    Foreach ($Patch in $CurrentStatus)
    {
	  $Status = Get-PatchStatus -EvalState $Patch.EvaluationState -ComplyState $Patch.ComplianceState
      $Output += [pscustomobject]@{
		KB  = "KB$($Patch.ArticleID)"
		Name = $Patch.Name
		EvaluationState = $Status.EvaluationState
		ComplianceState = $Status.ComplianceState
      }
    }
      Write-Host " "
      $Cycle = $Record.LoopCounter + 1
      If($CurrentStatus.Count -gt 0)
      {
        Write-Host "Software Update Status: (Patching Cycle:" $Cycle")" -ForegroundColor Green
      }
      $Output |FT 
    Write-Host " "
  }
 }
}
Else
{
  Write-Host "   There are no Beekeeper Execution Jobs running at this time" -ForegroundColor "yellow"

}

