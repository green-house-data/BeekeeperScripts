PARAM 
(
[Parameter(Mandatory=$True,
 HelpMessage="Provide SCCM Collection ID. Ex: LAB00014")][ValidateNotNullOrEmpty()]
 [String] $SCCMCollectionID,
[Parameter(Mandatory=$True,
 HelpMessage="Provide the drive location to the CSV containing the file name. Ex: C:\MyFiles\SCCMCollCSV.CSV")][ValidateNotNullOrEmpty()]
 [String]$CSVFileName
)
$GL = Get-Location
$delimiter = ','
$CollectionMemberList = @()
Try
{
  import-module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
  $SiteCode=Get-PSDrive -PSProvider CMSITE
  cd ((Get-PSDrive -PSProvider CMSite).Name + ':')

}
Catch
{
  Write-Host "[ERROR]`t SCCM Module couldn't be loaded. Script will stop!"
  Exit 1
}
$MemberCount = 0
$Collection = Get-CMCollection -CollectionId $SCCMCollectionID | Select-Object Name
$Members = Get-CMCollectionMember -CollectionId $SCCMCollectionID | Select-Object Name
foreach($Member in $Members)
{
  $CollMembers  = New-Object System.Object 
  $CollMembers| Add-Member -type NoteProperty -Name Node -Value $Member.Name
  $CollMembers| Add-Member -type NoteProperty -Name GroupName -Value $Collection.Name
  $CollMembers| Add-Member -type NoteProperty -Name GrpType -Value "Application Group"
  $CollMembers| Add-Member -type NoteProperty -Name Email -Value "DL@yourcompany.com"
  $CollMembers| Add-Member -type NoteProperty -Name SCOMMM -Value "No"
  $CollMembers| Add-Member -type NoteProperty -Name MMDuration -Value ""
  $CollMembers| Add-Member -type NoteProperty -Name MMIgnoreFail -Value "No"
  $CollMembers| Add-Member -type NoteProperty -Name ContPatchFail -Value "No"
  $CollMembers| Add-Member -type NoteProperty -Name ExclPatchFail -Value "Yes"
  $CollMembers| Add-Member -type NoteProperty -Name ContAnyFail -Value "No"
  $CollectionMemberList += $CollMembers
  $MemberCount++
}
$CollectionMemberList | ConvertTo-Csv -Delimiter $delimiter -NoTypeInformation | foreach { $_ -replace '^"','' -replace "`"$delimiter`"",$delimiter -replace '"$','' } | Out-File $CSVFileName -Force -Encoding ascii
Write-Host $MemberCount "servers exported to" $CSVFileName -ForegroundColor Green
Set-Location $GL