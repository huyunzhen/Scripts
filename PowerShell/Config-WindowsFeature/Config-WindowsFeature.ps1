#---------------------------------------------------
#START:  FUNCTIONS
#---------------------------------------------------
function Install-Feature {
	param (
		$WindowsFeature,
		$Reboot,
		$Enable
	)
	$OS = [Version](Get-WmiObject Win32_OperatingSystem).Version
	
	$isInstalled = (Get-WindowsFeature -name $WindowsFeature).installed

	if ((($isInstalled -eq $TRUE) -AND ($Enable -eq $TRUE)) -or (($isInstalled -eq $FALSE) -AND ($Enable -eq $FALSE))) {
		Write-Host "WFI:  $($WindowsFeature) feature install state and requested state match.  No action required."
		Write-Host "WFI:  $($WindowsFeature) is installed = $($isInstalled)"
		Write-Host "WFI`:  Requested state = $($Enable)"
		
	} elseif ($isInstalled -eq $TRUE -AND $Enable -eq $TRUE) {
		Write-Host "WFI:  $($WindowsFeature) feature install state and requested state do not match.  Action required."
		Write-Host "WFI:  $($WindowsFeature) is installed = $($isInstalled)"
		Write-Host "WFI:  Requested state eq $($Enable)"

		Switch ($Enable) {
			$TRUE { Install-WindowsFeature -name $WindowsFeature -IncludeAllSubFeature }
			$FALSE {
				if ($OS.version -le "6.1") { Remove-WindowsFeature -name $WindowsFeature }
				else { Uninstall-WindowsFeature -name $WindowsFeature }
			}
		}
		
		Switch ($Reboot) {
			$TRUE {
				Write-Host "$($WindowsFeature) feature change completed.  Reboot requested."
				Write-Host "Rebooting..."
				rs_shutdown -r -i -v
 			}
			$FALSE { Write-Host "$($WindowsFeature) feature change completed.  No reboot requested." }
		}
	}
}
#---------------------------------------------------
#END:  FUNCTIONS
#---------------------------------------------------

#---------------------------------------------------
#START:  INPUTS
#---------------------------------------------------

$WindowsFeatures	= $ENV:WINDOWS_FEATURE

#---------------------------------------------------
#END:  INPUTS
#---------------------------------------------------

Write-Host "$($WindowsFeatures)"

Import-Module ServerManager –verbose

if ($WindowsFeatures -contains "`;") { $WindowsFeatures = $WindowsFeatures.Split("`;") }
else { [array]$WindowsFeatures += $WindowsFeatures }

foreach ($WindowsFeature in $WindowsFeatures) {
	$Split			= $WindowsFeature.Split(",")

	$WindowsFeature	= $Split[0]
	$Reboot			= $Split[1]
	$Enable			= $Split[2]
	
	Install-Feature $WindowsFeature $Reboot $Enable
}