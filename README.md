# Cloud NVIDIA GameStream

## What is it?
A Powershell one-click solution to enable NVIDIA GeForce Experience GameStream on a cloud machine with a GRID supporting GPU. There was a [thread discussing this in the xda-developers forum](https://forum.xda-developers.com/showthread.php?t=2394478) but the whole process was unclear in which versions of the GRID drivers and GeForce Experience to use and required some tedious installation and workarounds since the GeForce Experience that supported it would automatically update to the newest one. This script will solve all the issues with one single script.

## Installation
Copy and paste these commands in the machine's powershell prompt:
```
Set-ExecutionPolicy Unrestricted;Invoke-WebRequest -Uri https://github.com/acceleration3/cloudgamestream/archive/master.zip -OutFile arch.zip;Add-Type -Assembly "System.IO.Compression.Filesystem";$dir = [string](Get-Location);[System.IO.Compression.ZipFile]::ExtractToDirectory($dir + "\arch.zip", $dir);cd cloudgamestream-master;./GFE_Setup.ps1
```

Or you can download the script and binaries from [here](https://github.com/acceleration3/cloudgamestream/archive/master.zip).

## Compatibility
Tested and working on the following:

* OS:
	* Windows 10 Pro build 2004
	* Windows Server Core 2019
	
* Platforms:
	* Azure NV6_Promo

**WARNING: Machines provided by Shadow.tech supposedly have incompatibility with GeForce Experience and may brick your VM. Use at your own risk.**

## FAQ
### Will this work on \<insert platform and instance name here\>?
  I have only tested this on Azure's NV6_Promo instance. I would like to build a list of platforms it currently supports, so if you've tested it yourself and it works, please message me on reddit `/u/acceleration3` with the information on your VM. If it doesn't work you can also message me with details and I will try and change the script to support your VM.

### The script didn't enable my GameStream at all.
  Remember to **not use this script on a Microsoft Remote Desktop session**. I recommend using AnyDesk as an alternative. If it still doesn't work then the script doesn't currently support your machine. 

### I can't connect to my VM using Moonlight.
  You need to forward the ports on your machine. The ports you need to forward are 47984, 47989, 48010 TCP and 47998, 47999, 48000, 48010 UDP. If you're having more problems try downloading the [Moonlight Internet Streaming Tool](https://github.com/moonlight-stream/Internet-Hosting-Tool/releases) and troubleshooting it.

### GeForce Experience requires me to login. Do I have to create/use an NVIDIA account?
  Yes.

### This GeForce Experience version doesn't support my game. What do I do?
  You can stream your entire desktop with GeForce Experience. Just add `C:\windows\system32\mstsc.exe` to the applications list and launch that with Moonlight.
