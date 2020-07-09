Param(
    [string]$url = 'http://localhost/BeekeeperApi/OPAS.svc/',
    [Parameter(Mandatory = $True)]
    [string]$ClName = "Test"
)

#requires -version 4

$contentType = "application/json;odata.metadata=minimal"
$headers = @{"Accept"="application/json"}

#Ensure $url is well formatted
$url = $url -replace '([^/])$','$1/'
if ($url -notmatch '/Opas.svc/$')
{
    $url = "$url/Opas.svc/"
}
If($Cluster -eq "Test")
{
   Write-Warning "Cluster/DAG/App Group Name not specified...terminating"
   break
}

Write-Verbose -Message "Attempting to connect to Web API on $url..." -Verbose

#Get all outstanding records
$records = ((Invoke-WebRequest -Uri ("$($url)PatchRecords?" + '$filter=Status eq ''Running'' or Completed eq false') -Method Get -Headers $headers -UseDefaultCredentials ).content | ConvertFrom-Json).value

#Cancel all outstanding records
if ($records.count -gt 0)
{    
    foreach ($record in $records)
    {
      If($record.'odata.type' -eq "OPASSvc.ClusterPatchRecord")
      {
       $Cl = ((Invoke-WebRequest -Uri ("$($url)Clusters?`$filter=ClusterId eq $($record.ClusterId)") -Method Get -Headers $headers -UseDefaultCredentials ).content | ConvertFrom-Json).value
      }
      If(($Cl.count -eq 1) -and ($Cl.ClusterName -eq $ClName))
        {
        If($record.'odata.type' -ne "OPASSvc.ClusterPatchRecord")
        {
         $Node = ((Invoke-WebRequest -Uri ("$($url)ClusterNodes?`$filter=NodeId eq $($record.NodeId)") -Method Get -Headers $headers -UseDefaultCredentials ).content | ConvertFrom-Json).value 
        }
        If($Node.ClusterID -eq $Cl.ClusterID)
        {
        Write-Verbose -Message "Cancelling patch record for $($Node.NodeName)  of $($ClName) as it is still marked as running or incomplete." -Verbose        
        $payload = [pscustomobject]@{
                "odata.type"=$record.'odata.type';
                StartTime=[DateTimeOffset]::Now.ToString("yyyy-MM-ddTHH:mm:ssK"); 
                EndTime=[DateTimeoffset]::Now.ToString("yyyy-MM-ddTHH:mm:ssK");
                Completed=$true;
                Status="Cancelled"                
        }
        
        if ([string]::IsNullOrWhiteSpace($record.StartTime) -eq $false)
        {
            $payload.StartTime = $record.StartTime
        }
        
        if ([string]::IsNullOrWhiteSpace($record.EndTime) -eq $false)
        {
            $payload.EndTime = $record.EndTime
        }

        $response = Invoke-WebRequest -Uri ("$($url)PatchRecords($($record.RecordId))") -Method Patch -Headers $headers -ContentType $contentType -Body (ConvertTo-Json $payload) -UseDefaultCredentials
        if ($response.StatusCode -ne 204)
        {
            Write-Error -Message "Error attempting to update PatchRecord - HTTP response was $($response.StatusDescription)"
        }
        }
        }
    }
}
else
{
    Write-Verbose -Message 'There are no PatchRecords currently marked as running' -Verbose
}

#Get all locked Clusters
$clusters = ((Invoke-WebRequest -Uri ("$($url)Clusters?" + '$filter=Status eq ''Patching''') -Method Get -Headers $headers -UseDefaultCredentials ).content | ConvertFrom-Json).value

#Unlock all locked clusters
if ($clusters.Count -gt 0)
{
    foreach ($cluster in $clusters)
    {
         If($cluster.ClusterName -eq $ClName)
        {
           Write-Verbose -Message "Unlocking $($cluster.ClusterName) as it is currently marked as patching." -Verbose
           $response = Invoke-WebRequest -Uri ("$($url)Clusters($($cluster.ClusterId))") -Method Patch -Headers $headers -ContentType $contentType -Body '{ Status : "Ready" }' -UseDefaultCredentials
           if ($response.StatusCode -ne 204)
           {
               Write-Error -Message "Error attempting to update cluster - HTTP response was $($response.StatusDescription)"
           }
        }
    }
}
else
{
    Write-Verbose -Message "No locked clusters detected." -Verbose
}