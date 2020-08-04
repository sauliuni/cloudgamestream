Param([Parameter(Mandatory=$false)] [Switch]$RebootSkip)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

Import-Module BitsTransfer
Start-Transcript -Path "Log.txt"

clear

Write-Output "Cloud based GameStream Preparation Tool"
Write-Output "by Acceleration3"
Write-Output ""

if($RebootSkip -eq $false)
{
    Write-Output "WARNING: Using Microsoft Remote Desktop will create a virtual monitor separate from the one running the NVIDIA GPU and prevent GeForce Experience from enabling the GameStream feature! You need to use another type of Remote Desktop solution such as AnyDesk or TeamViewer!"
    Write-Output ""
    $install1 = (Read-Host "You need to have an audio interface installed for GameStream to work. Install VBCABLE? (y/n)").ToLower();
    $install2 = (Read-Host "You also need the NVIDIA GRID Drivers installed. Install the tested and recommended ones? (y/n)").ToLower();

	if($install1 -eq "y")
	{
		$path = "Bin\vbcable.zip"
		if(![System.IO.File]::Exists($path))
		{
			Write-Output "Downloading VBCABLE..."
			Start-BitsTransfer "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" $path
		}
	}

	if($install2 -eq "y")
	{
		$path = "Bin\Drivers.exe"
		if(![System.IO.File]::Exists($path))
		{
			Write-Output "Downloading NVIDIA GRID Drivers..."
			Start-BitsTransfer "https://download.microsoft.com/download/b/8/f/b8f5ecec-b8f9-47de-b007-ac40adc88dc8/442.06_grid_win10_64bit_international_whql.exe" $path
		}
	}

    $path = "Bin\GFE.exe"
	if(![System.IO.File]::Exists($path))
	{
		Write-Output "Downloading GeForce Experience..."
		Start-BitsTransfer "https://us.download.nvidia.com/GFE/GFEClient/3.13.0.85/GeForce_Experience_Beta_v3.13.0.85.exe" $path
	}

	$path = "Bin\redist.exe"
	if(![System.IO.File]::Exists($path))
	{
		Write-Output "Downloading Visual C++ Redist 2015 x86..."
		Start-BitsTransfer "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe" $path
	}

	Write-Output "Downloads completed."

	if($install1 -eq "y")
	{
		Write-Output "Installing VBCABLE..."
		Expand-Archive -Path .\Bin\vbcable.zip -DestinationPath .\Bin\vbcable
		Start-Process -FilePath .\Bin\vbcable\VBCABLE_Setup_x64.exe -ArgumentList "-i","-h" -NoNewWindow -Wait
	}

	if($install2 -eq "y")
	{
		Write-Output "Installing NVIDIA GRID GPU drivers. The computer will restart and the script will re-run on startup."
		$directory = [string](Get-Location);
        $script = "-Command `"& " + [string](Get-Location) + "\GFE_Setup.ps1`" -RebootSkip";
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $script -WorkingDirectory $directory
        $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:30"
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GFESetup" -Description "GFESetup" | Out-Null

		Start-Process -FilePath .\Bin\Drivers.exe -ArgumentList "-s","-clean" -NoNewWindow -Wait
        Restart-Computer -Force
	}
}
else
{
    Unregister-ScheduledTask -TaskName "GFESetup" -Confirm:$false
    Write-Output "The script will continue from where it left off."
    Pause
}

Write-Output "Installing Visual C++ Redist 2015 x86..."
Start-Process -FilePath .\Bin\redist.exe -ArgumentList "/install","/quiet","/norestart" -NoNewWindow -Wait

Write-Output "Installing GeForce Experience..."
Start-Process -FilePath .\Bin\GFE.exe -ArgumentList "-s" -NoNewWindow -Wait

Write-Output "Enabling NVIDIA FrameBufferCopy..."
Start-Process -FilePath .\Bin\NvFBCEnable.exe -ArgumentList "-enable","-noreset" -NoNewWindow -Wait

Write-Output "Patching GeForce Experience to enable GameStream..."
Stop-Service -Name NvContainerLocalSystem
Start-Process -FilePath .\Bin\GFEPatch.exe -NoNewWindow -Wait -PassThru

Write-Output "Patching hosts file to block GeForce Experience updates..."
Copy-Item -Path .\Bin\hosts.txt -Destination C:\Windows\System32\drivers\etc\hosts

Write-Output "Disabling HyperV Monitor and GPU..."
displayswitch.exe /internal
Get-PnpDevice -Class "Display" -Status OK | where { $_.Name -notmatch "nvidia" } | Disable-PnpDevice -confirm:$false

Write-Output "Adding a GameStream rule to the Windows Firewall..."
New-NetFirewallRule -DisplayName "NVIDIA GameStream TCP" -Direction inbound -LocalPort 47984,47989,48010 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "NVIDIA GameStream UDP" -Direction inbound -LocalPort 47998,47999,48000,48010 -Protocol UDP -Action Allow

Write-Output "Done. You should now be able to use GameStream after you restart your computer."
$restart = (Read-Host "Would you like to restart now? (y/n)").ToLower();

if($restart -eq "y")
{
    Restart-Computer -Force
}
