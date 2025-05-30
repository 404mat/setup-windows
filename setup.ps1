#Requires -RunAsAdministrator

# Script for initial Windows setup: Customize settings, install Chocolatey, and packages...

# --- Configuration ---
$chocoInstallDir = "$env:ProgramData\chocolatey"  # Custom Chocolatey install location.
$packageList = @(
  @{ Name = "hwinfo"; Args = "" }
  @{ Name = "vlc"; Args = "" }
  @{ Name = "7zip"; Args = "" }
  @{ Name = "powertoys"; Args = "" }
  @{ Name = "zen-browser"; Args = "--pre" }
  @{ Name = "googlechrome"; Args = "--ignore-checksums" }
  @{ Name = "vscode"; Args = "" }
  @{ Name = "plex"; Args = "" }
  @{ Name = "spotify"; Args = "" }
  @{ Name = "discord.install"; Args = "" }
  @{ Name = "git"; Args = "" }
  @{ Name = "filezilla"; Args = "" }
  @{ Name = "qbittorrent"; Args = "" }
)

# --- Function Definitions  ---

# Function: Set a Windows Registry setting
function Set-SafeRegistry {
    param (
        [string]$KeyPath,
        [string]$ValueName,
        [object]$ValueData,
        [string]$ValueType
    )

    try {
        # Check if the key exists
        if (!(Test-Path -Path $KeyPath)) {
            # Create the key if it doesn't exist
            Write-Host "Creating registry key: $KeyPath" -ForegroundColor Yellow
            New-Item -Path $KeyPath -ItemType Directory -Force | Out-Null
        }

        # Try to set the registry value with the specified type
        Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -Type $ValueType -Force

        # Success Message
        Write-Host "Set Registry: $KeyPath\$ValueName to $ValueData (Type: $ValueType)" -ForegroundColor Green
    }
    catch {
        # Failure Messages
        Write-Error "FAILED: Setting Registry $KeyPath\$ValueName to $ValueData (Type: $ValueType): $($_.Exception.Message)"
    }
}

function Install-Chocolatey {
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Chocolatey is already installed." -ForegroundColor Green
            return
        }
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow

        # Set TLS 1.2
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

        # Bypass execution policy for this session only
        Set-ExecutionPolicy Bypass -Scope Process -Force

        # Run official install script
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Add Chocolatey bin folder to current session PATH
        $chocoBin = "$env:ProgramData\chocolatey\bin"
        if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $chocoBin })) {
            $env:PATH += ";$chocoBin"
            Write-Host "Added Chocolatey bin directory to PATH for this session." -ForegroundColor Yellow
        }

        Write-Host "Chocolatey installation complete! Restart your shell to use 'choco' command." -ForegroundColor Green
    }
    catch {
        Write-Error "Chocolatey installation failed: $($_.Exception.Message)"
        exit 1
    }
}

function Install-ChocolateyPackages {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Packages
    )
    
    Write-Host "Installing Chocolatey packages..." -ForegroundColor Yellow
    
    foreach ($pkg in $Packages) {
        $args = if ([string]::IsNullOrWhiteSpace($pkg.Args)) { @() } else { $pkg.Args.Split(" ") }
        Write-Host "Installing '$($pkg.Name)' with args '$($pkg.Args)'..." -ForegroundColor Green

        try {
            $argsList = @("install", $pkg.Name, "-y")
            if ($args.Length -gt 0) {
                $argsList += $args
            }

            $process = Start-Process -FilePath "choco" -ArgumentList $argsList -Wait -NoNewWindow -PassThru
            if ($process.ExitCode -ne 0) {
                Write-Warning "'$($pkg.Name)' installation failed with exit code $($process.ExitCode)."
            } else {
                Write-Host "'$($pkg.Name)' installed successfully!" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Error installing '$($pkg.Name)': $($_.Exception.Message)"
        }
    }
    
    Write-Host "Chocolatey package installation complete!" -ForegroundColor Green
}

# --- Main Script Execution ---

# 1. Customize Windows Settings
Write-Host "Customizing Windows settings..." -ForegroundColor Yellow

################ REGISTRY SETTINGS START ######################

## Disable Customer Experience Improvement Program (CEIP) ##
Set-SafeRegistry -KeyPath "HKLM:\SOFTWARE\Microsoft\SQMClient" -ValueName "CEIPEnable" -ValueData 0 -ValueType DWord

## Disable Scheduled Defrag ##  (Good for SSD systems)
Set-SafeRegistry -KeyPath "HKLM:\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" -ValueName "Enable" -ValueData "N" -ValueType String
Disable-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\"

## Disable Windows Tips  ## Windows tries to show helpful tips, many users find annoying
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -ValueName "SilentInstalledAppsEnabled" -ValueData 0 -ValueType DWord
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -ValueName "SystemPaneSuggestionsEnabled" -ValueData 0 -ValueType DWord
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -ValueName "NoToastApplicationNotification" -ValueData 1 -ValueType DWord

##  Enable Long Paths (Requires reboot)   ##  Allows file paths longer than 260 characters
Set-SafeRegistry -KeyPath "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -ValueName "LongPathsEnabled" -ValueData 1 -ValueType DWord

##  Remove Action Center Icon   ##
Set-SafeRegistry -KeyPath "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -ValueName "DisableNotificationCenter" -ValueData 1 -ValueType DWord

##  Disable Game Bar   ##
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\GameBar" -ValueName "ShowGameBar" -ValueData 0 -ValueType DWord
Set-SafeRegistry -KeyPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -ValueName "AllowGameDVR" -ValueData 0 -ValueType DWord

##  Disable Cortana   ##
Set-SafeRegistry -KeyPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ValueName "AllowCortana" -ValueData 0 -ValueType DWord

## Show File Extensions ##
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "HideFileExt" -ValueData 0 -ValueType DWord

##  Show hidden files, folders, and drives  ##
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "Hidden" -ValueData 1 -ValueType DWord
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ValueName "ShowSuperHidden" -ValueData 1 -ValueType DWord

## Disable Low Disk Space Check ##
Set-SafeRegistry -KeyPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoLowDiskSpaceChecks" -ValueData 1 -ValueType DWord

################ REGISTRY SETTINGS END ######################

Write-Host "Finished applying registry settings." -ForegroundColor Green


# 2. Install Chocolatey and it's packages
Write-Host "Installing Chocolatey and packages..." -ForegroundColor Yellow
Install-Chocolatey
Install-ChocolateyPackages -Packages $packageList

# 3. Finalize setup
refreshenv
Write-Host "Windows setup script completed!" -ForegroundColor Green