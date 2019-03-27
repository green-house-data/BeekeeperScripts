param 
(
    [parameter(mandatory=$true,
     helpmessage="provide the drive location to the csv containing the file name. ex: c:\myfiles\schedules.csv")][validatenotnullorempty()]
     [string]$CSVFileName
)

Function CreateSchedule {
    Param (
    [string][Parameter(Mandatory=$True)]$ScheduleName,
    [string][Parameter(Mandatory=$True)]$ScheduleJson
    )
    $requestUri = "$($Uri)"
    $requestUri = $requestUri += "Schedules"

    #Override Certificate validation behaviour so that self-signed certs, expired certs or non-trusted certs are not an issue
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$True}
    #Create WebRequest
    $webRequest = [System.Net.WebRequest]::Create($requestURI)
    $webRequest.Accept = 'application/json'
    $webRequest.ContentType = 'application/json;odata.metadata=minimal'
    $webRequest.Method = 'POST'
    $webRequest.UseDefaultCredentials = $true
    $bytePayload = [System.Text.Encoding]::ASCII.GetBytes($ScheduleJson)
    $webRequest.ContentLength = $bytePayload.Length
    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($bytePayload,0,$bytePayload.Length)
    $requestStream.Close()
   
    $response = $null

    Try
    {
       $response = $webRequest.GetResponse()
    }
    Catch [System.Net.WebException]
    {
       $response = $_.exception.Response
    }


    #Check to see if request was sucessfull
    If ($response.StatusCode -Match 'OK|Created')
    {
        Write-Host "Schedule ($ScheduleName) successfully created" -ForegroundColor "Green"
    }
    Else 
    {
        Write-Host "Schedule ($ScheduleName) was not successfully created" -ForegroundColor "Red"
    }
    $response.Close()

}

Function Get-New-Schedule-ID {
    Param (
    [string][Parameter(Mandatory=$True)]$ScheduleName)

    $requestUri = "$($Uri)"
    $requestUri = $requestUri += "Schedules?`$filter=Name eq '" + $ScheduleName + "'"
    $URI_Headers = @{ 'Accept' = 'application/json' }
    $Sched_Info = Invoke-RestMethod -Uri $requestUri -UseDefaultCredentials -Headers $URI_Headers
    return ($Sched_Info.Value.ScheduleId)
}


Function Get-Cluster-ID {
    Param (
    [string][Parameter(Mandatory=$True)]$ClusterName)

    $requestUri = "$($Uri)"
    $requestUri = $requestUri += "Clusters?`$filter=ClusterName eq '" + $ClusterName + "'"
    $URI_Headers = @{ 'Accept' = 'application/json' }
    $Cluster_Info = Invoke-RestMethod -Uri $requestUri -UseDefaultCredentials -Headers $URI_Headers
    return ($Cluster_Info.Value.ClusterId)
}

Function ClusterToSchedule {
    Param (
    [string][Parameter(Mandatory=$True)]$ClusterId,
    [string][Parameter(Mandatory=$True)]$ClusterName,
    [string][Parameter(Mandatory=$True)]$ScheduleName,
    [string][Parameter(Mandatory=$True)]$ScheduleJson
    )
    $requestUri = "$($Uri)"
    $requestUri = $requestUri +=  "/Clusters(" + $ClusterId + ")/`$links/Schedules" 

    #Override Certificate validation behaviour so that self-signed certs, expired certs or non-trusted certs are not an issue
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$True}
    #Create WebRequest
    $webRequest = [System.Net.WebRequest]::Create($requestURI)
    $webRequest.Accept = 'application/json'
    $webRequest.ContentType = 'application/json;odata.metadata=minimal'
    $webRequest.Method = 'POST'
    $webRequest.UseDefaultCredentials = $true
    $bytePayload = [System.Text.Encoding]::ASCII.GetBytes($ScheduleJson)
    $webRequest.ContentLength = $bytePayload.Length
    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($bytePayload,0,$bytePayload.Length)
    $requestStream.Close()
   
    $response = $null

    Try
    {
       $response = $webRequest.GetResponse()
    }
    Catch [System.Net.WebException]
    {
       $response = $_.exception.Response
    }


    #Check to see if request was sucessfull
    If ($response.StatusCode -Match 'NoContent')
    {
        Write-Host "    Schedule ($ScheduleName) successfully linked with Cluster ($ClusterName)" -ForegroundColor "cyan"
    }
    Else 
    {
        Write-Host "Schedule ($ScheduleName) was not successfully linked with Cluster ($ClusterName)" -ForegroundColor "Red"
    }

    $response.Close()

}


$GroupList = @{}
$URI = "http://localhost/BeekeeperApi/OPAS.svc/"
$FileContents = Import-CSV -Path $CSVFileName
Foreach($Line in $FileContents)
{
    $InSchedule = $Line| Select-Object @{Name="Name";Expression={$_."Name"}}, @{Name="Clusters";Expression={$_."Clusters"}}, @{Name="DayNumber";Expression={$_."DayNumber"}}, @{Name="DayOffset";Expression={$_."DayOffset"}}, @{Name="MaxRuntime";Expression={$_."MaxRuntime"}}, @{Name="MonthIncrement";Expression={$_."MonthIncrement"}}, @{Name="OriginalDayNumber";Expression={$_."OriginalDayNumber"}}, @{Name="PatchDay";Expression={$_."PatchDay"}}, @{Name="Recurring";Expression={$_."Recurring"}}, @{Name="WeekNumber";Expression={$_."WeekNumber"}}, @{Name="Enabled";Expression={$_."Enabled"}}, @{Name="PatchDate";Expression={$_."PatchDate"}}
    $GroupList = $InSchedule.Clusters.split("|")

    $InSchedule.Clusters = $GroupList
    If ($InSchedule.Recurring -eq "Yes") {
        $InSchedule.Recurring = $true
    }
    Else {
        $InSchedule.Recurring = $false
    }

    If ($InSchedule.Enabled -eq "Yes") {
        $InSchedule.Enabled = $true
    }
    Else {
        $InSchedule.Enabled = $false
    }
    $InSchedule.DayNumber = [Int]$InSchedule.DayNumber
    $InSchedule.DayOffset = [Int]$InSchedule.DayOffSet
    $InSchedule.MaxRuntime = [Int]$InSchedule.MaxRunTime
    $InSchedule.MonthIncrement = [Int]$InSchedule.MonthIncrement   
    $InSchedule.OriginalDayNumber = [Int]$InSchedule.OriginalDayNumber
    $InSchedule.WeekNumber = [Int]$InSchedule.WeekNumber
    $InSchedule.PatchDate = "{0:yyyy-MM-ddThh:mm:sszzz}" -f ([datetime]$InSchedule.PatchDate)
    $InSchedule.psobject.Properties.remove('Clusters')
    $InScheduleJson =  $InSchedule |ConvertTo-Json
    CreateSchedule -ScheduleName $InSchedule.Name -ScheduleJson $InScheduleJson
    $ScheduleId = Get-New-Schedule-ID -ScheduleName $InSchedule.Name
    Foreach($Group in $GroupList)
    {
        $CL_ID = Get-Cluster-ID -ClusterName $Group
        If($CL_ID -ne $null)
        {
           $ClusterToSchedule =  @{"url" = "http://localhost/BeekeeperApi/opas.svc/Schedules("+ $ScheduleId +")"}
           $ClusterToScheduleJson = $ClusterToSchedule | ConvertTo-Json
           ClusterToSchedule -ClusterId $CL_ID  -ClusterName $Group -ScheduleName $InSchedule.Name -ScheduleJson $ClusterToScheduleJson
        }
        Else 
        {
           Write-Host "Cluster ($Group) does not exist, schedule cannot be linked" -ForegroundColor "Red"
        }           
    }
}

