#Requires -RunAsAdministrator

# Script for initial Windows setup: Customize settings, install Chocolatey, and packages...

# --- Configuration ---
$chocoInstallDir = "C:\Chocolatey"  # Custom Chocolatey install location.
$packageList = @(  # Add desired Chocolatey packages here.
  "hwinfo",
  "vlc",
  "7zip",
  "powertoys",
  "zen-browser",
  "googlechrome",
  "vscode",
  "microsoft-windows-terminal",
  "plex",
  "spotify",
  "discord.install",
  "git",
  "filezilla",
  "qbittorrent"
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
        if (!(Test-Path -Path "Registry::$KeyPath")) {
            # Create the key if it doesn't exist
            Write-Host "Creating registry key: $KeyPath" -ForegroundColor Yellow
            New-Item -Path "Registry::$KeyPath" -ItemType Directory -Force | Out-Null
        }

        # Try to set the registry value with the specified type
        Set-ItemProperty -Path "Registry::$KeyPath" -Name $ValueName -Value $ValueData -Type $ValueType -Force

        # Success Message
        Write-Host "Set Registry: $KeyPath\$ValueName to $ValueData (Type: $ValueType)" -ForegroundColor Green
    }
    catch {
        # Failure Messages
        Write-Error "FAILED: Setting Registry $KeyPath\$ValueName to $ValueData (Type: $ValueType): $($_.Exception.Message)"
    }
}

# Function: Install Chocolatey
function Install-Chocolatey {
    try {
        # Check if already installed
        if (Get-Command choco -ErrorAction SilentlyContinue) {
          Write-Host "Chocolatey is already installed." -ForegroundColor Green
          return # exit install function
        }
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow

         # Ensure the installation directory exists.
        if (!(Test-Path -Path $chocoInstallDir )) {
            New-Item -ItemType Directory -Path $chocoInstallDir
        }

      # Define TLS for compatibility
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityPointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) -InstallDir $chocoInstallDir;

        # Add Chocolatey to the PATH. This persists
        $envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if (-not $envPath.Contains("$chocoInstallDir\bin")) {
            [Environment]::SetEnvironmentVariable("PATH", "$envPath;$chocoInstallDir\bin", "Machine")
            Write-Host "Chocolatey bin directory added to PATH (machine scope). Restart your new and future sessions to properly connect choco!" -ForegroundColor Yellow
        }
        else {
           Write-Host "Chocolatey already in PATH" -ForegroundColor Green
        }

        Write-Host "Chocolatey installation complete!" -ForegroundColor Green

    }
    catch {
        Write-Error "Chocolatey installation failed: $($_.Exception.Message)"
        exit 1 # stop all execution for critical error
    }
}

# Function: Install Chocolatey Packages
function Install-ChocolateyPackages {
    param (
        [string[]]$Packages # accept from variable
    )
    Write-Host "Installing Chocolatey packages..." -ForegroundColor Yellow
    foreach ($package in $Packages) {
        Write-Host "Installing '$package'..." -ForegroundColor Green
        try {
            choco install $package -y --source="'https://community.chocolatey.org/api/v2/'"
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "'$package' installation failed with exit code $($LASTEXITCODE)."
            } else {
                Write-Host "'$package' installed successfully!" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Error installing '$package': $($_.Exception.Message)"
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
Set-SafeRegistry -KeyPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Defrag" -ValueName "Action" -ValueData "{18294FA6-EB8F-4A1A-A943-66B4C9780E6D}" -ValueType String

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


Write-Host "Windows setup script completed!" -ForegroundColor Green