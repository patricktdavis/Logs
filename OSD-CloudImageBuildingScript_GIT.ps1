#=============================================================================
#region SCRIPT DETAILS
#=============================================================================

<#
.SYNOPSIS
Build Process for new WINRE image with commands current as of 7/19/2021 - Paddy Davis

.EXAMPLE
PS C:\> OSD-CloudImageBuildingScript.ps1

.Notes
While Autopilot Profiles are not needed for the WINRE image - here is how to grab and convert them (Remove Quoation Marks)
"Install-Module Microsoft.Graph
$creds = Get-Credential
Connect-MSGraph -Credential $creds
Get-AutopilotProfile | Select-Object displayname
Get-AutopilotProfile | Where-Object DisplayName -EQ '' | ConvertTo-AutopilotConfigurationJSON | Out-File -FilePath C:\Path\To\File\Name.json -Encoding ASCII"

.Requires
Latest Windows 10 ADK and Windows 10 ADKPE to be installed on the machine before running.

#>

#=============================================================================
#endregion
#=============================================================================

#=============================================================================
#region EXECUTION
#=============================================================================

#Cleanup of expired PS Modules - Best Practice
$Modules = 'OSD','OSDBUIDER'
foreach ($Module in $Modules) {
    Write-Host $Module
    Get-InstalledModule $Module -AllVersions -Verbose
    Remove-Module -Name $Module -Force -Verbose
    Uninstall-Module -Name $Module -Force -Verbose #OSDBuilder can cause module install issues
}

#Install Latest Module
Install-Module -Name OSD -Force -Verbose
New-OSDCloud.template -WinRE -Verbose #-WINRE needed to add wireless network capablity
New-OSDCloud.workspace -WorkspacePath C:\OSDCloud -Verbose

#Add JSON files (if any), Cloud Drivers, Wallpaper, Webscript Path to WinRE image.
Edit-OSDCloud.winpe -CloudDriver Dell,HP,Nutanix,VMware,WiFi -Wallpaper 'C:\App\Backgrounds\Expanse.jpg' -Workspacepath C:\OSDCloud -WebPSScript https://raw.githubusercontent.com/patricktdavis/OSDCloud/main/OSDCloud-Hennepin.ps1 -Verbose

#Building the iso files
New-OSDCloud.iso -Verbose

#=============================================================================
#endregion
#=============================================================================
#=============================================================================
#DISM commands for Updating the Boot WIM file with Drivers
#=============================================================================

if (Test-Path -Path C:\App\Mount -ne $true -Verbose) {
    mkdir -Path C:\App\Mount -Force -Verbose
}

Get-WindowsImage -ImagePath C:\App\USB-Builds\Deploy_Github_DockDrivers\sources\boot.wim -Verbose
Mount-WindowsImage -ImagePath C:\App\USB-Builds\Deploy_Github_DockDrivers\sources\boot.wim -Index 1 -Path C:\App\Mount
Add-WindowsDriver -Path C:\App\Mount -Driver C:\App\DockDrivers -Recurse -ForceUnsigned -Verbose
Dismount-WindowsImage -Path C:\App\Mount -Save -CheckIntegrity -Verbose

#=============================================================================
#endregion
#=============================================================================