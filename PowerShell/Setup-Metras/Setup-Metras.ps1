<#
	.SYNOPSIS 
		Renames a server, adds it to a domain, and places it into a specific OU.
	.DESCRIPTION
		Join-DomainWithInputs.ps1 Renames a server, then uses native PowerShell to create the AD account, place it into a specific OU, and join the server into the domain.  DNS is also set to the primary and secondary DC's as given in the inputs.
	.PARAMETER $ADFQDN
		Fully Qualified Domain Name to join.
	.PARAMETER $ADUser
		Active Directory user name with permission to join a server to the domain.
	.PARAMETER $ADOUPath
		OU path to place the new server.
	.PARAMETER $DomainPwd
		Password for the domain account.		
	.PARAMETER $LocUser
		Local user name with permission to join a server to the domain.
	.PARAMETER $LocalPwd
		Password for the local user.
	.PARAMETER $NewSysName
		New name for the server.		
	.PARAMETER $PriDCIP
		IP Address for the Primary Domain Controller.  This will be used as the Primary DNS address.
	.PARAMETER $SecDCIP
		IP Address for the Secondary Domain Controller.  This will be used as the Secondary DNS address.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays in the RightScale Dashboard only.
	.NOTES
		Name:       Join-DomainWithInputs.ps1
		Author:     Jes Brouillette - RightScale
		Last Edit:  05/10/2010 00:35 CST
		Purpose:	Renames a server, adds it to a domain, and places it into a specific OU.  For use as a RightScript.
#>

#==== Start: Script Variables ================================================#

$source			= $ENV:SOURCE_URL
$destination	= $ENV:DESTINATION_FOLDER
$name			= $ENV:FILE_NAME
$Provision_Key	= $ENV:PROV_KEY

$netWebClient	= New-Object System.Net.WebClient

#==== Finish: Script Variables ===============================================#

Write-Host "Starting download action - $name"
Write-Host "Source - $source"
Write-Host "Destination - $destination"

$file = $source.Split("/")[-1]
if (!(Test-Path $destination)) {New-Item $destination -ItemType Directory -ErrorAction Stop}
if ($destination.Length-1 -ne "\") { $destination = $destination + "\" + $file }
else { $destination = $destination + $file }

$netWebClient.downloadfile($source,$destination)

Start-Process msiexec -ArgumentList $cmdArgs -Wait

#==== Finish =================================================================#