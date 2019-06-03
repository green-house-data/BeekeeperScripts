param 
(
    [parameter(mandatory=$true,
     helpmessage="provide the drive location to the csv containing the file name. ex: c:\myfiles\LinkTasks.csv")][validatenotnullorempty()]
     [string]$CSVFileName
)

Function Link-ValTasks {
    Param (
    [string][Parameter(Mandatory=$True)]$ValTasksName,
    [string][Parameter(Mandatory=$True)]$ClusterName,
    [string][Parameter(Mandatory=$True)]$Phase,
    [string][Parameter(Mandatory=$True)]$ValTasksJson
    )
    $requestUri = "$($Uri)"
    $requestUri = $requestUri += "ValidationTaskLinks"
    $statusCode =$null

    #Override Certificate validation behaviour so that self-signed certs, expired certs or non-trusted certs are not an issue
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$True}
    #Create WebRequest
    $webRequest = [System.Net.WebRequest]::Create($requestURI)
    $webRequest.Accept = 'application/json'
    $webRequest.ContentType = 'application/json;odata.metadata=minimal'
    $webRequest.Method = 'POST'
    $webRequest.UseDefaultCredentials = $true
    $bytePayload = [System.Text.Encoding]::ASCII.GetBytes($ValTasksJson)
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
        Write-Host "Validation Task ($ValTasksName) linked to Cluster ($ClusterName) at Phase ($Phase) successfully created" -ForegroundColor "Green"
    }
    $response.Close()

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

Function Get-Task-ID {
    Param (
    [string][Parameter(Mandatory=$True)]$TaskName)

    $requestUri = "$($Uri)"
    $requestUri = $requestUri += "ValidationTasks?`$filter=Name eq '" + $TaskName + "'"
    $URI_Headers = @{ 'Accept' = 'application/json' }
    $Task_Info = Invoke-RestMethod -Uri $requestUri -UseDefaultCredentials -Headers $URI_Headers
    return ($Task_Info.Value.TaskId)
}

$GroupList = @{}
$URI = "http://localhost/BeekeeperApi/OPAS.svc/"
$FileContents = Import-CSV -Path $CSVFileName
Foreach($Line in $FileContents)
{
    $InValTasks = $Line| Select @{Name="Group";Expression={$_."Group"}}, @{Name="Task";Expression={$_."Task"}}, @{Name="Phase";Expression={$_."Phase"}}, @{Name="SeqNum";Expression={$_."SeqNum"}}
    $CL_ID = Get-Cluster-ID -ClusterName $InValTasks.Group
    $Task_ID = Get-Task-ID -TaskName $InValTasks.Task
    $InValTasks.SeqNum = [Int]$InValTasks.SeqNum
    $objTaskLink = New-Object System.Object
    $objTaskLink| Add-Member -NotePropertyName "ClusterId" -NotePropertyValue $CL_ID
    $objTaskLink| Add-Member -NotePropertyName "ValidationTaskId" -NotePropertyValue $Task_ID
    $objTaskLink| Add-Member -NotePropertyName "Phase" -NotePropertyValue $InValTasks.Phase
    $objTaskLink| Add-Member -NotePropertyName "SequenceNumber" -NotePropertyValue $InValTasks.SeqNum
    $InValTasksJson =  $objTaskLink |ConvertTo-Json
    Link-ValTasks -ClusterName $InValTasks.Group -ValTasksName $InValTasks.Group -Phase $InValTasks.Phase  -ValTasksJson $InValTasksJson
}

