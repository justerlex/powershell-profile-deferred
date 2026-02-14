### PowerShell Profile — Setup
### Fork of ChrisTitusTech/powershell-profile with performance optimizations.
###
### USAGE (elevated PowerShell):
###   irm "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1" | iex
###
### WHAT THIS DOES:
###   1. Installs all dependencies (Oh My Posh, Nerd Fonts, Chocolatey, fzf, Terminal-Icons, zoxide, fastfetch)
###   2. Downloads the profile as your active PowerShell profile
###   3. Patches BOTH PowerShell 7+ and Windows PowerShell 5.1 directories
###   4. Backs up any existing profiles before touching anything
###
### SAFE TO RE-RUN: Detects existing installs and updates in place.

# ═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURATION — change these if you fork the repo
# ═══════════════════════════════════════════════════════════════════════════════

$Config = @{
    # Where the profile lives (link to YOUR repo)
    RepoRoot        = "https://raw.githubusercontent.com/justerlex/powershell-profile-deferred/main"

    # Oh My Posh theme
    OmpThemeName    = "cobalt2"
    OmpThemeUrl     = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"

    # Nerd Fonts — installed via zip download (doesn't need OMP in PATH yet)
    FontName        = "CascadiaCode"
    FontDisplayName = "CaskaydiaCove NF"
    FontVersion     = "3.2.1"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PREFLIGHT CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

# Must run elevated — font install + choco need admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    return
}

function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-Warning "Internet connection is required but not available."
        return $false
    }
}

if (-not (Test-InternetConnection)) {
    return
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PowerShell Profile — Setup                          " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
#  DEPENDENCY INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════════

$totalSteps = 7

# ── Oh My Posh ──
Write-Host "[1/$totalSteps] Installing Oh My Posh..." -ForegroundColor Yellow
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
    # Refresh PATH so oh-my-posh is available immediately
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "  Oh My Posh installed." -ForegroundColor Green
} catch {
    Write-Error "  Failed to install Oh My Posh: $_"
}

# ── Nerd Fonts (CaskaydiaCove — CTT's default) ──
Write-Host "[2/$totalSteps] Installing CaskaydiaCove Nerd Font..." -ForegroundColor Yellow
try {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains $Config.FontDisplayName) {
        $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$($Config.FontVersion)/$($Config.FontName).zip"
        $zipFilePath = "$env:TEMP\$($Config.FontName).zip"
        $extractPath = "$env:TEMP\$($Config.FontName)"

        Write-Host "  Downloading font archive..." -ForegroundColor DarkGray
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)
        while ($webClient.IsBusy) { Start-Sleep -Seconds 2 }

        Write-Host "  Extracting and installing fonts..." -ForegroundColor DarkGray
        Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
            if (-not (Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        Remove-Item -Path $extractPath -Recurse -Force
        Remove-Item -Path $zipFilePath -Force
        Write-Host "  $($Config.FontDisplayName) installed." -ForegroundColor Green
    } else {
        Write-Host "  $($Config.FontDisplayName) already installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed to install $($Config.FontDisplayName): $_"
}

# ── Chocolatey ──
Write-Host "[3/$totalSteps] Installing Chocolatey..." -ForegroundColor Yellow
try {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  Chocolatey already installed." -ForegroundColor Green
    } else {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "  Chocolatey installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed to install Chocolatey: $_"
}

# ── Terminal-Icons ──
Write-Host "[4/$totalSteps] Installing Terminal-Icons module..." -ForegroundColor Yellow
try {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Write-Host "  Terminal-Icons already installed." -ForegroundColor Green
    } else {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force -SkipPublisherCheck
        Write-Host "  Terminal-Icons installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed to install Terminal-Icons: $_"
}

# ── zoxide ──
Write-Host "[5/$totalSteps] Installing zoxide..." -ForegroundColor Yellow
try {
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Write-Host "  zoxide already installed." -ForegroundColor Green
    } else {
        winget install -e --accept-source-agreements --accept-package-agreements ajeetdsouza.zoxide
        Write-Host "  zoxide installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed to install zoxide: $_"
}

# ── fzf + PSFzf ──
Write-Host "[6/$totalSteps] Installing fzf + PSFzf module..." -ForegroundColor Yellow
try {
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        Write-Host "  fzf already installed." -ForegroundColor Green
    } else {
        winget install -e --accept-source-agreements --accept-package-agreements junegunn.fzf
        Write-Host "  fzf installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed to install fzf: $_"
}
try {
    if (Get-Module -ListAvailable -Name PSFzf) {
        Write-Host "  PSFzf module already installed." -ForegroundColor Green
    } else {
        Install-Module -Name PSFzf -Repository PSGallery -Force -SkipPublisherCheck
        Write-Host "  PSFzf module installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed to install PSFzf module: $_"
}

# ── fastfetch ──
Write-Host "[7/$totalSteps] Installing fastfetch..." -ForegroundColor Yellow
try {
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        Write-Host "  fastfetch already installed." -ForegroundColor Green
    } else {
        winget install -e --accept-source-agreements --accept-package-agreements Fastfetch-cli.Fastfetch
        Write-Host "  fastfetch installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed to install fastfetch: $_"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PROFILE PATCHING
# ═══════════════════════════════════════════════════════════════════════════════

function Install-Profile {
    param(
        [string]$ProfileDir,
        [string]$Edition
    )

    Write-Host ""
    Write-Host "Patching $Edition profile in [$ProfileDir]..." -ForegroundColor Cyan

    # Create directory if it doesn't exist
    if (-not (Test-Path $ProfileDir)) {
        New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
        Write-Host "  Created profile directory." -ForegroundColor DarkGray
    }

    $profileFile = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"
    $backupFile  = Join-Path $ProfileDir "oldprofile.ps1"

    # ── Detect what's currently installed ──
    if (Test-Path $profileFile) {
        $existingContent = Get-Content $profileFile -Raw -ErrorAction SilentlyContinue

        if ($existingContent -match "Fork of ChrisTitusTech/powershell-profile") {
            # Our fork already — update in place
            Write-Host "  Found existing fork profile — updating." -ForegroundColor DarkGray

        } elseif ($existingContent -match "Deferred CTT Profile Wrapper") {
            # Old wrapper version — back it up, clean install
            Write-Host "  Found old wrapper profile — backing up to [$backupFile]" -ForegroundColor DarkGray
            Copy-Item -Path $profileFile -Destination $backupFile -Force
            # Also clean up leftover ctt-profile.ps1
            $cttFile = Join-Path $ProfileDir "ctt-profile.ps1"
            if (Test-Path $cttFile) {
                Remove-Item -Path $cttFile -Force
                Write-Host "  Removed leftover ctt-profile.ps1" -ForegroundColor DarkGray
            }

        } elseif ($existingContent -match "DO NOT MODIFY THIS FILE\. THIS FILE IS HASHED") {
            # Unpatched CTT profile — back it up
            Write-Host "  Found existing CTT profile — backing up to [$backupFile]" -ForegroundColor DarkGray
            Copy-Item -Path $profileFile -Destination $backupFile -Force

        } else {
            # Some other profile — back it up
            Write-Host "  Backing up existing profile to [$backupFile]" -ForegroundColor DarkGray
            Copy-Item -Path $profileFile -Destination $backupFile -Force
        }
    } else {
        Write-Host "  No existing profile found — fresh install." -ForegroundColor DarkGray
    }

    # ── Download the profile ──
    Write-Host "  Downloading profile..." -ForegroundColor DarkGray
    try {
        $profileUrl = "$($Config.RepoRoot)/Microsoft.PowerShell_profile.ps1"
        Invoke-RestMethod $profileUrl -OutFile $profileFile
        Write-Host "  Profile installed at [$profileFile]" -ForegroundColor Green
    } catch {
        Write-Error "  Failed to download profile: $_"
        return
    }

    # ── Download Oh My Posh theme ──
    $themeFile = Join-Path $ProfileDir "$($Config.OmpThemeName).omp.json"
    if (-not (Test-Path $themeFile)) {
        Write-Host "  Downloading Oh My Posh theme..." -ForegroundColor DarkGray
        try {
            Invoke-RestMethod -Uri $Config.OmpThemeUrl -OutFile $themeFile
            Write-Host "  Theme saved to [$themeFile]" -ForegroundColor Green
        } catch {
            Write-Warning "  Failed to download theme — oh-my-posh will fall back to remote."
        }
    } else {
        Write-Host "  Oh My Posh theme already present." -ForegroundColor Green
    }

    Write-Host "  $Edition profile patched." -ForegroundColor Green
}

# ── Patch both PowerShell editions ──
$coreDir    = "$env:USERPROFILE\Documents\PowerShell"
$desktopDir = "$env:USERPROFILE\Documents\WindowsPowerShell"

Install-Profile -ProfileDir $coreDir    -Edition "PowerShell 7+"
Install-Profile -ProfileDir $desktopDir -Edition "Windows PowerShell 5.1"

# ═══════════════════════════════════════════════════════════════════════════════
#  DONE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Setup complete!                                     " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Installed to:" -ForegroundColor White
Write-Host "    PowerShell 7+  : $coreDir" -ForegroundColor DarkGray
Write-Host "    PowerShell 5.1 : $desktopDir" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  File layout (per directory):" -ForegroundColor White
Write-Host "    Microsoft.PowerShell_profile.ps1  <- profile" -ForegroundColor DarkGray
Write-Host "    cobalt2.omp.json                  <- Oh My Posh theme" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Dependencies:" -ForegroundColor White
Write-Host "    Oh My Posh, CaskaydiaCove NF, Chocolatey," -ForegroundColor DarkGray
Write-Host "    Terminal-Icons, zoxide, fzf, PSFzf, fastfetch" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Commands:" -ForegroundColor White
Write-Host "    Update-Profile    - pull latest profile from repo" -ForegroundColor Yellow
Write-Host "    Update-PowerShell - check for PowerShell updates" -ForegroundColor Yellow
Write-Host "    Show-Help         - list all available commands" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Restart your terminal" -ForegroundColor DarkGray
Write-Host "    2. Set font to 'CaskaydiaCove NF' in your terminal settings" -ForegroundColor DarkGray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
