PARAM 
(
[Parameter(Mandatory=$True,
 HelpMessage="Provide the drive location to the CSV containing the file name. Ex: C:\MyFiles\AssetMgmt.CSV")][ValidateNotNullOrEmpty()]
 [String]$CSVFileName
)

$connection= new-object system.data.sqlclient.sqlconnection #Set new object to connect to sql database 
$connection.ConnectionString ='server=SVRPATCH;database=AssetMgmt_GenericCompany;trusted_connection=True' # Connectiong to database with window authentication 
$connection.open() #Connecting successful 

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand #setting object to use sql commands 


$SqlQuery1 = "SELECT  MachineName, Department FROM MachineAssets where AOR-Code = '0721'"
$SqlCmd1.CommandText = $SqlQuery1
$SqlAdapter1 = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter1.SelectCommand = $SqlCmd1
$SqlCmd1.Connection = $connection1
$DataSet1 = New-Object System.Data.DataSet
$SqlAdapter1.Fill($DataSet1) | Out-Null
$connection1.Close()
$Results1 = $DataSet1.Tables[0]
$PrevNode = " "
$AssetCount = 0
ForEach ($Item in $Results1.Rows)
{
    $SeverName = $Item.MachineName
    $DeptName  = $Item.Department

    $Assets  = New-Object System.Object 
    $Assets| Add-Member -type NoteProperty -Name Node -Value $ServerName
    $Assets| Add-Member -type NoteProperty -Name GroupName -Value $DeptName
    $Assets| Add-Member -type NoteProperty -Name GrpType -Value "Application Group"
    $Assets| Add-Member -type NoteProperty -Name Email -Value "DL@yourcompany.com"
    $Assets| Add-Member -type NoteProperty -Name SCOMMM -Value "No"
    $Assets| Add-Member -type NoteProperty -Name MMDuration -Value ""
    $Assets| Add-Member -type NoteProperty -Name MMIgnoreFail -Value "No"
    $Assets| Add-Member -type NoteProperty -Name ContPatchFail -Value "No"
    $Assets| Add-Member -type NoteProperty -Name ExclPatchFail -Value "Yes"
    $Assets| Add-Member -type NoteProperty -Name ContAnyFail -Value "No"

    $AssetMemberList += $Assets
    $AssetCount++
}

$AssetMemberList | ConvertTo-Csv -Delimiter $delimiter -NoTypeInformation | foreach { $_ -replace '^"','' -replace "`"$delimiter`"",$delimiter -replace '"$','' } | Out-File $CSVFileName -Force -Encoding ascii
Write-Host $AssetCount "servers exported to" $CSVFileName -ForegroundColor Green
