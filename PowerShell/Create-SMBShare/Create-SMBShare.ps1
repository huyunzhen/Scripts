$ShareName		= $ENV:NEW_SHARE_NAME
$DriveLetter	= $ENV:NEW_DATA_VOLUME
$Description	= $ENV:NEW_SHARE_DESCRIPTION

$SharePath = "{0}:\{1}" -f $DriveLetter,$ShareName

$IsInstalled = Get-WindowsFeature FS-FileServer -
Get-WindowsFeature RSAT-File-Services

Write-Host "CREATE_SMB_SHARE:  Creating $ShareName at $SharePath"

if (!(Test-Path $SharePath)) {
	Write-Host "CREATE_SMB_SHARE:  $SharePath does not exist.  Creating."
	$IsCreated = New-Item $SharePath -ItemType Directory -Force
	if ($IsCreated) { Write-Host "CREATE_SMB_SHARE:  $SharePath created successfully." }
	else { Write-Host "CREATE_SMB_SHARE:  $SharePath was not able to be created.  Exiting." ; Exit }

	$IsCreated = $NULL
}

$IsShared = Get-SMBShare -Name $ShareName
if ($IsShared) {
	Write-Host "CREATE_SMB_SHARE:  $ShareName already exists.  No work to do."
} else {
	Write-Host "CREATE_SMB_SHARE:  Creating \\$($ENV:COMPUTERNAME)\$ShareName."
	$IsCreated = New-SmbShare -Name $ShareName -Path $SharePath -Description $Description -FullAccess "Everyone"
	if ($IsCreated) { Write-Host "CREATE_SMB_SHARE:  \\$($ENV:COMPUTERNAME)\$ShareName created successfully." }
	else { Write-Host "CREATE_SMB_SHARE:  \\$($ENV:COMPUTERNAME)\$ShareName was not created." }
}