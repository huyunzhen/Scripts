$LicFirstName		= $ENV:TS_LIC_FIRSTNAME
$LicLastName		= $ENV:TS_LIC_LASTNAME
$LicCompany			= $ENV:TS_LIC_COMPANY
$LicRegion			= $ENV:TS_LIC_REGION
$InstallOption		= $ENV:TS_LIC_INSTALL_OPTION
$ConnectionMethod	= $ENV:TS_LIC_CONNECT_METHOD
$LicenseType		= $ENV:TS_LIC_TYPE
$AgreementType		= $ENV:TS_AGREEMENT_TYPE
$AgreementNumber	= $ENV:TS_AGREEMENT_NUMBER
$ProductVersion		= $ENV:TS_PRODUCT_VERSION	# 4=(2012/2012R2),2=(2008/2008R2),1=(2003),0=(2000)
$ProductType		= $ENV:TS_PRODUCT_TYPE		# 0=(Device),1=(User),2=(VDI STD),3=(VDI PREM)
$LicCount			= $ENV:TS_LIC_COUNT

Write-Host "RDS_LIC_CFG:  Checking for AD Tools installation"
$IsInstalled = Get-WindowsFeature RSAT-AD-Tools | Select -expand Installed

if (!$IsInstalled) {
	Write-Host "RDS_LIC_CFG:  RSAT-AD-PowerShell & RSAT-AD-Tools are not installed.  Installing now."
	Add-WindowsFeature RSAT-AD-PowerShell,RSAT-AD-Tools
	Write-Host "RDS_LIC_CFG:  Completed.  Rebooting to complete the RSAT tools."
	rs_shutdown -r -i
} else {
	Write-Host "RDS_LIC_CFG:  RSAT-AD-PowerShell & RSAT-AD-Tools are installed.  Continuing."
}

Write-Host "RDS_LIC_CFG:  Importing the RDS module."
Import-Module RemoteDesktopServices

Write-Host "RDS_LIC_CFG:  Import completed.  Validating the current RDS License state."
$IsActivated = Get-Item RDS:\LicenseServer\ActivationStatus | select -ExpandProperty CurrentValue

if ($IsActivated -eq 0) {
	Write-Host "RDS_LIC_CFG:  RDS License is currently not activated.  Setting prerequisites."
	Set-Item -Path RDS:\licenseserver\configuration\Firstname -Value $LicFirstName
	Set-Item -Path RDS:\licenseserver\configuration\Lastname -Value $LicLastName
	Set-Item -Path RDS:\licenseserver\configuration\Company -Value $LicCompany
	Set-Item -Path RDS:\licenseserver\configuration\CountryRegion -Value $LicRegion

	Write-Host "RDS_LIC_CFG:  Prerequisites completed.  Setting activation."
	Set-Item -Path RDS:\LicenseServer\ActivationStatus -Value 1 -ConnectionMethod AUTO -Reason 5

	Write-Host "RDS_LIC_CFG:  Applying RDS Licenses"
	New-Item -path RDS:\LicenseServer\LicenseKeyPacks -InstallOption $InstallOption -ConnectionMethod $ConnectionMethod -LicenseType $LicenseType -AGREEMENTTYPE $AgreementType -AGREEMENTNUMBER $AgreementNumber -PRODUCTVERSION $ProductVersion -PRODUCTTYPE $ProductType -LICENSECOUNT $LicCOunt

	Write-Host "RDS_LIC_CFG:  RDS Licenses completed.  Rebooting."
	rs_shutdown -r -i
}

Write-Host "RDS_LIC_CFG:  Importing the AD module."
Import-Module ActiveDirectory

Write-Host "RDS_LIC_CFG:  AD module imported.  Validating AD group membership of the RDS License server."
$Group = Get-ADGroupMember "Terminal Server License Servers"

if ($Group.Name -notcontains $ENV:COMPUTERNAME) {
	Write-Host "RDS_LIC_CFG:  RDS License server was not part of the AD group.  Adding."
	$Computer = Get-ADComputer $ENV:COMPUTERNAME
	$AddMember = Add-ADGroupMember -Identity $Group -Members $Computer -Passthrough
	if ($AddMember) { Write-Host "RDS_LIC_CFG:  RDS License Server is now part of the AD group." }
	else { Write-Host "RDS_LIC_CFG:  RDS License Server was not able to be added." }
}