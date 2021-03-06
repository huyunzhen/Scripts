#---------------------------------------------------
#START:  FUNCTIONS
#---------------------------------------------------
function Install-Feature {
	param (
		$feature
	)
	$isInstalled = (Get-Windowsfeature -name $feature).installed

	if($isInstalled -eq "True") {
		Write-Host "WFC`:  $($feature) feature is installed"
	} else {
		Write-Host "WFC`:  Installing $($feature) Feature"
		Install-WindowsFeature -name $feature
	}
}
#---------------------------------------------------
#END:  FUNCTIONS
#---------------------------------------------------

#Inputs
$adDomain		= [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName

$adAdminAcct	= $env:AD_WFC_ADMIN_ACCT
$adAdminAcctPwd	= $env:AD_WFC_ADMIN_ACCT_PWD
$wfcClusterName	= $env:WFC_CLUSTER_NAME

$pAcct			= "{0}\{1}" -f $adDomain,$adAdminAcct
$pAcctPwd		= $adAdminAcctPwd | convertto-securestring -AsPlainText -Force

$localHost		= [System.Net.Dns]::GetHostName()

Write-Host "Creating Credential Object for - $pAcct"
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $pAcct,$pAcctPwd

#--Adding necessary features were applicable
Install-Feature Failover-Clustering
Install-Feature RSAT-Clustering-Mgmt
Install-Feature RSAT-Clustering-PowerShell

Write-Host "Importing Module`: FailoverClusters"
Import-Module FailoverClusters

$psScripBlock  = {
	param (
		$adAdminAcct,
		$adAdminAcctPwd,
		$wfcClusterName,
		$localhost
	)
	
	$localHost		= [System.Net.Dns]::GetHostName()
	$adDomain		= [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName

	$pAcct			= $adDomain + '\' + $adAdminAcct
	$pAcctPwd		= $adAdminAcctPwd

	Write-Host "Importing Module`: FailoverClusters for the scriptblock"
	Import-Module FailoverClusters

	#---------------------------------------------------
	#START:  MAIN
	#---------------------------------------------------

	Write-Host "WFC`: Getting Clusters"
    try {
		$retCluster = Get-Cluster -Domain $adDomain
	}
	catch
	{
		Write-Output "Exception getting Cluster"
		Write-Output $_
	}

	Write-Host ""
	Write-Host "Clusters"
	Write-Host "-----------------------"
	Write-Host $retClusters
	Write-Host ""

	#--check if Cluster already exists
	if($retClusters -match $wfcClusterName) {
		Write-Host "Cluster found - $wfcClusterName"
		Write-Host "Getting Cluster Info"
		
		Write-Host "Getting Cluster - $wfcClusterName"
		$sess_wfcClusters = Get-Cluster -Name $localHost -Domain $adDomain
		$sess_wfcClusters
		
		Write-Host ""
		Write-Host "WFC Cluster - $wfcClusterName"
		Write-Host "--------------------------------"
		Write-Host $retCluster
		Write-Host ""
		
		Write-Host "Getting Cluster Nodes - $wfcClusterName"
		$retClusterNodes = Get-ClusterNode -Name $localHost -Domain $adDomain | select cluster,name,state

		Write-Host ""
		Write-Host "Cluster Nodes - $wfcClusterName"
		Write-Host "--------------------------------"
		Write-Host $retClusterNodes
		Write-Host ""
		
		if($retClusterNodes -match $localHost)
		{
		  Write-Host "$localHost is already a member of Cluster $wfcClusterName"
		}
		else
		{
		   Write-Host "$localHost is not a member of Cluster $wfcClusterName"
		 
		 
		 #TODO: add node to cluster
		}
	}
	else
	{
		Write-Host "Cluster not found - $wfcClusterName"
		
		#TODO: create new WFC Cluster
		Write-Host "Creating WFC - $wfcClusterName"  
		$retNewCluster = New-Cluster -node $localHost -Name $wfcClusterName -NoStorage
		  
		Write-Host $retNewCluster
	}
}

Invoke-Command -ScriptBlock $psScripBlock -ComputerName $localHost -Credential $cred -ArgumentList $adAdminAcct,$adAdminAcctPwd,$wfcClusterName,$localhost

Write-Host "Script finished"