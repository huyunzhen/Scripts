$AD_Domain		= $ENV:AD_DOMAIN_NAME
$AD_NetBios		= $ENV:AD_NETBIOS_NAME
$AD_OU			= $ENV:AD_OU_NAME
$AD_Password	= $ENV:AD_ADMIN_PASSWORD
$AD_User		= $ENV:AD_ADMIN_USERNAME
$AD_New_Name	= $ENV:AD_NEW_SERVER_NAME

$Local_Password	= $ENV:ADMIN_PASSWORD
$Local_Username	= $ENV:ADMIN_ACCOUNT_NAME

$ComputerName	= $ENV:COMPUTERNAME
$ComputerDomain	= GWMI Win32_Computersystem | Select -ExpandProperty Domain

$Domain_User = "{0}\{1}" -f $AD_NetBios,$AD_User

if ($Local_Username) { $Local_User = "{0}\{1}" -f ".",$Local_Username }
else { $Local_User = ".\Administrator" }

$AD_Secure_Password	= ConvertTo-SecureString $AD_Password -AsPlainText -Force
$AD_Credential		= New-Object System.Management.Automation.PSCredential $Domain_User,$AD_Secure_Password

$Local_Secure_Password	= ConvertTo-SecureString $Local_Password -AsPlainText -Force
$Local_Credential		= New-Object System.Management.Automation.PSCredential $Local_User,$Local_Secure_Password

$IsJoined	= $ComputerDomain -match $AD_Domain
$IsRenamed	= $ComputerName -match $AD_New_Name

if ($AD_New_Name.length -ge 1) {
	if ($IsRenamed) {
		Write-Host "JOIN_DOMAIN:  $ComputerName is already $AD_New_Name."
	} else {
		Write-Host "JOIN_DOMAIN:  Renaming $ComputerName to $AD_New_Name."
		if ($IsJoined) {	$Rename = Rename-Computer -NewName $AD_New_Name -DomainCredential $AD_Credential -PassThru }
		else {				$Rename	= Rename-Computer -NewName $AD_New_Name -PassThru }
		$Renamed	= $Rename.HasSucceeded
		if ($Renamed) {
			Write-Host "JOIN_DOMAIN:  $ComputerName has been renamed to $AD_New_Name."
			Write-Host "JOIN_DOMAIN:  Continuing to joing the domain."
		} else {
			Write-Host "JOIN_DOMAIN:  $ComputerName was not renamed.  Exiting script"
			Write-Host "JOIN_DOMAIN:  $($_.Exception.Message)"
			Exit
		}
	}
}

if ($IsJoined) {
	Write-Host "JOIN_DOMAIN:  $ComputerName is already part of $AD_Domain."
	Write-Host "JOIN_DOMAIN:  No work to do."
} else {
	Write-Host "JOIN_DOMAIN:  $ComputerName is not part of $AD_Domain."
	Write-Host "JOIN_DOMAIN:  Joining $ComputerName to $AD_Domain."
	
	if ($Renamed) {	$Join	= Add-Computer -DomainName $AD_Domain -OUPath $AD_OU -Credential $AD_Credential -LocalCredential $Local_Credential -Options AccountCreate,JoinWithNewName -Force -PassThru }
	else {			$Join	= Add-Computer -DomainName $AD_Domain -OUPath $AD_OU -Credential $AD_Credential -LocalCredential $Local_Credential -Force -PassThru }
	
	$Joined	= $Join.HasSucceeded
	if ($Joined) {
		Write-Host "JOIN_DOMAIN:  $ComputerName has joined $AD_Domain."
		Write-Host "JOIN_DOMAIN:  Rebooting."
		rs_shutdown -r -i
	} else {
		Write-Host "JOIN_DOMAIN:  $ComputerName was not joined to $AD_Domain."
		Write-Host "JOIN_DOMAIN:  $($_.Exception.Message)"
	}
}

if ($Renamed -and !$Joined) {
	Write-Host "JOIN_DOMAIN:  $ComputerName was renamed, but not rejoined to the domain. Rebooting to finalize the rename."
	rs_shutdown -r -i
}