#---------------------------------------------------
#START:  FUNCTIONS
#---------------------------------------------------
function Install-Feature {
	param (
		$WindowsFeature,
		$Reboot,
		$Enable
	)
	[Version]$OS = (Get-WmiObject Win32_OperatingSystem).Version
	
	$isInstalled = (Get-WindowsFeature -name $WindowsFeature).installed

	if ((($isInstalled -eq $TRUE) -AND ($Enable -eq "Enable")) -or (($isInstalled -eq $FALSE) -AND ($Enable -eq "Disable"))) {
		Write-Host "WFI:  $($WindowsFeature) feature install state and requested state match.  No action required."
		Write-Host "WFI:  $($WindowsFeature) is installed = $($isInstalled)"
		Write-Host "WFI:  Requested state = $($Enable)"
		
	} elseif (($isInstalled -eq $FALSE) -AND ($Enable -eq "Enable")) {
		Write-Host "WFI:  $($WindowsFeature) feature install state and requested state do not match.  Action required."
		Write-Host "WFI:  $($WindowsFeature) is installed = $($isInstalled)"
		Write-Host "WFI:  Requested state eq $($Enable)"

		Switch ($Enable) {
			"Enable" {
				if ($OS -lt "6.2.9200") {
					Write-Host "WFI:  Found Windows 2012 or older.  Add-WindowsFeature -name $($WindowsFeature) -IncludeAllSubFeature"
					$Install = Add-WindowsFeature -name $WindowsFeature -IncludeAllSubFeature
				} else {
					Write-Host "WFI:  Found Windows 2012R2 or newer.  Install-WindowsFeature -name $($WindowsFeature) -IncludeAllSubFeature"
					$Install = Install-WindowsFeature -name $WindowsFeature -IncludeAllSubFeature
				}
			}
			"Disable" {
				if ($OS -lt "6.2.9200") {
					Write-Host "WFI:  Found Windows 2012 or older.  Remove-WindowsFeature -name $($WindowsFeature)"
					$Install = Remove-WindowsFeature -name $WindowsFeature
				} else {
					Write-Host "WFI:  Found Windows 2012R2 or newer.  Uninstall-WindowsFeature -name $($WindowsFeature)"
					$Install = Uninstall-WindowsFeature -name $WindowsFeature
				}
			}
		}
		if ($Install.ExitCode -eq "Success") {
			Switch ($Reboot) {
				$TRUE {
					Write-Host "WFI:  $($WindowsFeature) feature change completed.  Reboot requested."
					Write-Host "WFI:  Rebooting..."
					rs_shutdown -r -i -v
	 			}
				$FALSE { Write-Host "WFI:  $($WindowsFeature) feature change completed.  No reboot requested." }
			}
		} else {
			Write-Host "WFI:  $($WindowsFeature) feature change did not complete successfully.  Exit code::$($Install.ExitCode).  Break."
			Break
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

Import-Module ServerManager

if ($WindowsFeatures -contains ";") { $WindowsFeatures = $WindowsFeatures.Split(";") }
else { $WindowsFeatures = @($WindowsFeatures) }

foreach ($WindowsFeature in $WindowsFeatures) {
	$Split		= $WindowsFeature.Split(",")
	
	$Feature	= $Split[0]
	$Reboot		= $Split[1]
	$Enable		= $Split[2]
	
	Install-Feature $Feature $Reboot $Enable
}