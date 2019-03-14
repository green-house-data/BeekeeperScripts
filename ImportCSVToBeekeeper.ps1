PARAM 
(

[Parameter(Mandatory=$True,
 HelpMessage="Provide the drive location to the CSV containing the file name. Ex: C:\MyFiles\SCCMCollCSV.CSV")][ValidateNotNullOrEmpty()]
 [String]$CSVFileName
)

Function Create-Cluster {
    Param (
    [string][Parameter(Mandatory=$True)]$ClusterName,
    [string][Parameter(Mandatory=$True)]$ClusterJson
    )
   $requestUri = "$($Uri)/"
    $requestUri = $requestUri += "Clusters"
    $statusCode =$null

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$True}
    $webRequest = [System.Net.WebRequest]::Create($requestURI)
    $webRequest.Accept = 'application/json'
    $webRequest.ContentType = 'application/json;odata.metadata=minimal'
    $webRequest.Method = 'POST'
    $webRequest.UseDefaultCredentials = $true
    $bytePayload = [System.Text.Encoding]::ASCII.GetBytes($ClusterJson)
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


    If ($response.StatusCode -Match 'OK|Created')
    {
        Write-Host "Cluster ($clusterName) successfully created" -ForegroundColor "cyan"
    }

    $response.Close()

}
Function Get-ServerGroup {
    Param (
    [string][Parameter(Mandatory=$True)]$ClusterJson,
    [string][Parameter(Mandatory=$True)]$ClusterName
    )
    $clusters = $null
    [array]$arrClusters = $null
    $clusterCount = 0
    $lastClusterId = 0
    $Found = "N"

        $requestUri = "$($Uri)"
        $requestUri = $requestUri += 'Clusters?$filter=ClusterId gt ' + $lastClusterId
        $headers = @{'Accept'='application/json'}
        $results = Invoke-WebRequest -Uri $requestUri -UseDefaultCredentials -Headers $headers

        $output = ($results.content | convertFrom-json)
        $clusters = $output.value

        $ClusterCheck = $clusters | Where-Object {$_.ClusterName -like $ClusterName}
        $clusterCount = $output.value.Count
        If ($output.value.Count -ne 0) {
            $lastClusterId = $output.value.ClusterId[-1]
        }
        If($ClusterCheck -ne $null)
        { 
           $Found = "Y"
        }

        If ($output.value.Count -ne 0) {
            $lastClusterId = $output.value.ClusterId[-1]
        }
    If($Found -eq "N")
    {
        Create-Cluster -ClusterName $ClusterName -ClusterJson $ClusterJson
        $results = Invoke-WebRequest -Uri $requestUri -UseDefaultCredentials -Headers $headers

        $Newoutput = ($results.content | convertFrom-json)
        $Newclusters += $Newoutput.value
        $NewClusterInfo = $Newclusters | Where-Object {$_.ClusterName -like $ClusterName}
        Return $NewClusterInfo.ClusterId
    }
    Else
    {
      
        Return $ClusterCheck.ClusterId
    }

}

Function Get-ClusterNodes {
    Param (
    [string][Parameter(Mandatory=$True)]$json,
    [string][Parameter(Mandatory=$True)]$clusterName,
    [string][Parameter(Mandatory=$True)]$clusterID,
    [string][Parameter(Mandatory=$True)]$nodeName
    )
    $nodes = $null
    $Found = "N"
    [array]$arrNodes = $null
    $nodeCount = 0
    $lastNodeId = 0
    $requestUri = "$($Uri)/"
    $requestUri = $requestUri += 'ClusterNodes?$filter=((ClusterId eq ' + $ClusterID + ') and (NodeId gt ' + $lastNodeId + '))'

    $headers = @{'Accept'='application/json'}
    $results = Invoke-WebRequest -Uri $requestUri -UseDefaultCredentials -Headers $headers
    $output = ($results.content | convertFrom-json)
    $nodes = $output.value
    $nodeCount = $output.value.Count
    If ($output.value.Count -ne 0) {
        $lastNodeId = $output.value.NodeId[-1]
    }
    $NodeCheck = $Nodes | Where-Object {$_.NodeName -like $NodeName}
    If($NodeCheck -ne $null)
     { 
       $Found = "Y"
     }
    If($Found -eq "N")
    {
      Add-ClusterNodes -json $Json -clusterName $ClusterName -nodeName $NodeName
    }
 

}
Function Add-ClusterNodes {
    Param (
    [string][Parameter(Mandatory=$True)]$json,
    [string][Parameter(Mandatory=$True)]$clusterName,
    [string][Parameter(Mandatory=$True)]$nodeName
    )

    $requestUri = "$($Uri)"
    $requestUri = $requestUri += 'ClusterNodes'
    $statusCode =$null

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$True}
    $webRequest = [System.Net.WebRequest]::Create($requestURI)
    $webRequest.Accept = 'application/json'
    $webRequest.ContentType = 'application/json;odata.metadata=minimal'
    $webRequest.Method = 'POST'
    $webRequest.UseDefaultCredentials = $true
    $bytePayload = [System.Text.Encoding]::ASCII.GetBytes($json)
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


    If ($response.StatusCode -Match 'OK|Created')
    {
        Write-Host "    Node ($nodeName) successfully added to cluster ($clusterName)" -ForegroundColor "green"
    }

    $response.Close()

}

Function Update-Cluster {
    Param (
    [string][Parameter(Mandatory=$True)]$json,
    [string][Parameter(Mandatory=$True)]$clusterId,
    [string][Parameter(Mandatory=$True)]$clusterName
    )

    $requestUri = "$($Uri)"
    $requestUri = $requestUri += "Clusters($clusterId)"

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$True}
    $webRequest = [System.Net.WebRequest]::Create($requestURI)
    $webRequest.Accept = 'application/json'
    $webRequest.ContentType = 'application/json;odata.metadata=minimal'
    $webRequest.Method = 'PATCH'
    $webRequest.UseDefaultCredentials = $true
    $bytePayload = [System.Text.Encoding]::ASCII.GetBytes($json)
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


    If ($response.StatusCode -Match 'NoContent')
    {
        Write-Host "    Exchane DAG ($clusterName) Mode information successfully updated" -ForegroundColor "cyan"
    }
    Else {
        Write-Host "Exchange DAG ($clusterName) was not updated successfully and requires further investigation" -ForegroundColor "red"
    }

    $response.Close()

}

$GrpName = ""
$URI = "http://jfhlabnewbk/BeekeeperApi/OPAS.svc/"
$FileContents = Import-CSV -Path $CSVFileName
Foreach($Line in $FileContents)
{
    $InAppGrp = $Line| Select @{Name="ClusterType";Expression={$_."GrpType"}}, @{Name="ClusterName";Expression={$_."GroupName"}}, @{Name="NotificationAddress";Expression={$_."Email"}}, @{Name="StartMaintenanceMode";Expression={$_."SCOMMM"}}, @{Name="MaintenanceModeDuration";Expression={$_."MMDuration"}}, @{Name="IgnoreMaintenanceFailures";Expression={$_."MMIgnoreFail"}}, @{Name="ContinueAfterFailedPatches";Expression={$_."ContPatchFail"}}, @{Name="ExcludeFailedPatches";Expression={$_."ExclPatchFail"}}, @{Name="ContinueAfterAnyFailure";Expression={$_."ContAnyFail"}}

    If ($InAppGrp.StartMaintenanceMode -eq "Yes") {
        $InAppGrp.StartMaintenanceMode = $true
        If (($InAppGrp.MaintenanceModeDuration -eq $null) -or ($InAppGrp.MaintenanceModeDuration -eq "")) {
            # Remove the MM duration value as it is not required/specified
            $InAppGrp.PSObject.Properties.Remove('MaintenanceModeDuration')
        }
        If ($InAppGrp.IgnoreMaintenanceFailures -eq "Yes") {
            $InAppGrp.IgnoreMaintenanceFailures = $true
        }
        Else {
            $InAppGrp.IgnoreMaintenanceFailures = $false
        }
    }
    Else {
        # No maintenance mode is required
        $InAppGrp.StartMaintenanceMode = $false
        $InAppGrp.PSObject.Properties.Remove('MaintenanceModeDuration')
        $InAppGrp.IgnoreMaintenanceFailures = $false
    }

    # Determine if ignore patch failures data is required/formatted properly
    If ($InAppGrp.ContinueAfterFailedPatches -eq "Yes") {
        $InAppGrp.ContinueAfterFailedPatches = $true
        If ($InAppGrp.ExcludeFailedPatches -eq "Yes") {
            $InAppGrp.ExcludeFailedPatches = $true
        }
        Else {
            $InAppGrp.ExcludeFailedPatches = $false
        }
    }
    Else {
        $InAppGrp.ContinueAfterFailedPatches = $false
        $InAppGrp.ExcludeFailedPatches = $false
    }

    # Determine if ignore any failures data is required/formatted properly
    If ($InAppGrp.ContinueAfterAnyFailure -eq "Yes") {
        $InAppGrp.ContinueAfterAnyFailure = $true
    }
    Else {
        $InAppGrp.ContinueAfterAnyFailure = $false
    }

    $InAppGrpJson =  $InAppGrp |ConvertTo-Json
    $CL_ID = Get-ServerGroup -ClusterJson $InAppGrpJson -ClusterName $Line.GroupName
    If($Line.GrpType -eq "Exchange DAG Cluster")
    {
       If ($Line.IPLessDAG -eq "Yes") 
       {
          $IPLess = $True
       }
       Else
       {
          $IPLess = $False
       }
       $DAGGrp = $InAppGrp
       $DAGGrp.psobject.Properties.remove('ClusterName')
       $DAGGrp.psobject.Properties.remove('ClusterType')
       $DAGGrp | Add-Member -NotePropertyName "IPLess" -NotePropertyValue $IPLess
       $DAGJson = $DAGGrp |ConvertTo-Json
       Update-Cluster -json $DAGjson -clusterId $CL_ID -clusterName $Line.GroupName

    }
    If($Line.GrpType -eq "Application Group")
    {
       $psoNode = New-Object PSObject
       $psoNode | Add-Member -NotePropertyName NodeName -NotePropertyValue $Line.Node
       $psoNode | Add-Member -NotePropertyName ClusterId -NotePropertyValue $CL_ID
       $ClusterNodeJson = $psoNode | ConvertTo-Json
       Get-ClusterNodes -json $ClusterNodeJson -clusterName $Line.GroupName -ClusterID $CL_ID -nodeName $Line.Node
  }
}
