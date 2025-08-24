#Requires -RunAsAdministrator

# Script for initial Windows setup: Customize settings, install Chocolatey, and packages...

# --- Configuration ---
$chocoInstallDir = "$env:ProgramData\chocolatey"  # Custom Chocolatey install location.
$packageList = @(
  @{ Name = "filezilla"; Args = "" }
)
$wingetPackageList = @(
    # tools
    @{ Name = "Rem0o.FanControl"; Source = "winget" }
    @{ Name = "Microsoft.PowerToys"; Source = "winget" }
    @{ Name = "7zip.7zip"; Source = "winget" }

    # UX
    @{ Name = "TranslucentTB"; Source = "msstore" }
    @{ Name = "Lively Wallpaper"; Source = "msstore" }
    @{ Name = "xanderfrangos.twinkletray"; Source = "winget" }
    @{ Name = "LocalSend.LocalSend"; Source = "winget" }
    @{ Name = "Armin2208.WindowsAutoNightMode"; Source = "winget" }

    # Social
    @{ Name = "WhatsApp"; Source = "msstore" }

    # CLI Tools
    @{ Name = "Fastfetch-cli.Fastfetch"; Source = "winget" }
    @{ Name = "GitHub.cli"; Source = "winget" }
    @{ Name = "pnpm.pnpm"; Source = "winget" }
    @{ Name = "Git.Git"; Source = "winget" }
    @{ Name = "astral-sh.uv"; Source = "winget" }
    @{ Name = "Schniz.fnm"; Source = "winget" }
    @{ Name = "StephanDilly.gitui"; Source = "winget" }

    # Dev tools
    @{ Name = "Docker.DockerDesktop"; Source = "winget" }
    @{ Name = "Microsoft.VisualStudioCode"; Source = "winget" }
    @{ Name = "Yaak.app"; Source = "winget" }

    # Content tools
    @{ Name = "Figma.Figma"; Source = "winget" }
    @{ Name = "ogdesign.Eagle"; Source = "winget" }
    @{ Name = "Notion.Notion"; Source = "winget" }
    @{ Name = "Notion.NotionCalendar"; Source = "winget" }
    @{ Name = "Google.GoogleDrive"; Source = "winget" }

    # Entertainment
    @{ Name = "qBittorrent.qBittorrent"; Source = "winget" }
    @{ Name = "Spotify.Spotify"; Source = "winget" }
    @{ Name = "Discord.Discord"; Source = "winget" }
    @{ Name = "Plex.Plex"; Source = "winget" }
    @{ Name = "VideoLAN.VLC"; Source = "winget" }

    # Browsers
    @{ Name = "Google.Chrome"; Source = "winget" }
    @{ Name = "Zen-Team.Zen-Browser"; Source = "winget" }
)

$dotfilesNames = @(".gitconfig", ".gitignore", ".zshrc")
$dotfilesUrl = "https://raw.githubusercontent.com/404mat/setup-mac/refs/heads/main/dotfiles"

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

function Install-WingetPackages {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable[]]$Packages
    )
    Write-Host "Installing Winget packages..." -ForegroundColor Yellow
    foreach ($pkg in $Packages) {
        $name = $pkg.Name
        $source = $pkg.Source
        Write-Host "Installing '$name' from source '$source'..." -ForegroundColor Green
        try {
            winget install $name -s $source --accept-package-agreements --accept-source-agreements -h --silent
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "'$name' installation failed with exit code $LASTEXITCODE."
            } else {
                Write-Host "'$name' installed successfully!" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Error installing '$name': $($_.Exception.Message)"
        }
    }
    Write-Host "Winget package installation complete!" -ForegroundColor Green
}

function Download-Dotfiles {
    param (
        [string]$dotfilesUrl,
        [string[]]$dotfilesNames
    )

    foreach ($name in $dotfilesNames) {
        $url = "${dotfilesUrl}/${name}"
        $destination = "$HOME\$name"

        try {
            Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
            Write-Host "Downloaded '$name' to '$destination'" -ForegroundColor Green
        } catch {
            Write-Error "Failed to download '$url': $($_.Exception.Message)"
        }
    }
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

# Download and set wallpaper
$wallpaperUrl = "https://raw.githubusercontent.com/404mat/setup-windows/main/wallpaper.jpg"
$wallpaperPath = "$env:USERPROFILE\Pictures\wallpaper.jpg"
try {
    Write-Host "Downloading wallpaper from $wallpaperUrl..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -UseBasicParsing
    Write-Host "Wallpaper downloaded successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to download wallpaper: $($_.Exception.Message)"
}
# Set the downloaded wallpaper
Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
# SPI_SETDESKWALLPAPER = 20, SPIF_UPDATEINIFILE = 0x01, SPIF_SENDCHANGE = 0x02
[Wallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3)

# Install Chocolatey and it's packages
Write-Host "Installing Chocolatey and packages..." -ForegroundColor Yellow
Install-Chocolatey
Install-ChocolateyPackages -Packages $packageList

# Install Winget packages
Install-WingetPackages -Packages $wingetPackageList

# Download dotfiles
Write-Host "Downloading dotfiles..." -ForegroundColor Yellow
Download-Dotfiles -dotfilesUrl $dotfilesUrl -dotfilesNames $dotfilesNames

# WSL
wsl --install Ubuntu --no-launch

# Finalize setup
refreshenv # Refresh Chocolatey environment variables
Write-Host "Windows setup script completed!" -ForegroundColor Green