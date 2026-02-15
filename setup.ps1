### PowerShell Profile — Setup
### Fork of ChrisTitusTech/powershell-profile with performance optimizations.
###
### USAGE (elevated PowerShell):
###   irm "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1" | iex
###
### WHAT IT DOES:
###   1. Installs dependencies (Oh My Posh, Iosevkata + CaskaydiaCove Nerd Fonts, Chocolatey, Terminal-Icons, zoxide, fzf, fastfetch, Git, croc)
###   2. Downloads the profile into both PowerShell 7+ and 5.1 directories
###   3. Injects the Flexoki color scheme into Windows Terminal
###   4. Backs up existing profiles before overwriting
###
### Safe to re-run — skips anything already installed.

# ═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

$Config = @{
    RepoRoot              = "https://raw.githubusercontent.com/justerlex/powershell-profile-deferred/main"
    OmpThemeName          = "cobalt2"
    OmpThemeUrl           = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json"
    FontName              = "CascadiaCode"
    FontDisplayName       = "CaskaydiaCove NF"
    FontVersion           = "3.2.1"
    IosevkataApi          = "https://api.github.com/repos/ningw42/Iosevkata/releases/latest"
    IosevkataDisplayName  = "Iosevkata Nerd Font"
    DefaultFont           = "Iosevkata Nerd Font"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PREFLIGHT
# ═══════════════════════════════════════════════════════════════════════════════

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    return
}

try {
    Test-Connection -ComputerName github.com -Count 1 -ErrorAction Stop | Out-Null
} catch {
    Write-Warning "Internet connection is required but not available."
    return
}

Write-Host ""
Write-Host "  PowerShell Profile Setup" -ForegroundColor Cyan
Write-Host "  ========================" -ForegroundColor DarkGray
Write-Host ""

# ═══════════════════════════════════════════════════════════════════════════════
#  DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════

$totalSteps = 10

# [1] Oh My Posh
Write-Host "[1/$totalSteps] Oh My Posh..." -ForegroundColor Yellow
try {
    winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "  Done." -ForegroundColor Green
} catch {
    Write-Error "  Failed: $_"
}

# [2] CaskaydiaCove Nerd Font
Write-Host "[2/$totalSteps] CaskaydiaCove Nerd Font..." -ForegroundColor Yellow
try {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains $Config.FontDisplayName) {
        $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$($Config.FontVersion)/$($Config.FontName).zip"
        $zipPath = "$env:TEMP\$($Config.FontName).zip"
        $extractPath = "$env:TEMP\$($Config.FontName)"

        Invoke-WebRequest -Uri $fontZipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
            if (-not (Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        Remove-Item $extractPath -Recurse -Force
        Remove-Item $zipPath -Force
        Write-Host "  Done." -ForegroundColor Green
    } else {
        Write-Host "  Already installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# [3] Iosevkata Nerd Font (default)
Write-Host "[3/$totalSteps] Iosevkata Nerd Font..." -ForegroundColor Yellow
try {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains $Config.IosevkataDisplayName) {
        $release = Invoke-RestMethod -Uri $Config.IosevkataApi
        $tag = $release.tag_name
        $fontZipUrl = "https://github.com/ningw42/Iosevkata/releases/download/$tag/IosevkataNerdFont-$tag.zip"
        $zipPath = "$env:TEMP\IosevkataNerdFont.zip"
        $extractPath = "$env:TEMP\IosevkataNerdFont"

        Invoke-WebRequest -Uri $fontZipUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
            if (-not (Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        Remove-Item $extractPath -Recurse -Force
        Remove-Item $zipPath -Force
        Write-Host "  Done." -ForegroundColor Green
    } else {
        Write-Host "  Already installed." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# [4] Chocolatey
Write-Host "[4/$totalSteps] Chocolatey..." -ForegroundColor Yellow
try {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  Already installed." -ForegroundColor Green
    } else {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "  Done." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# [5] Terminal-Icons
Write-Host "[5/$totalSteps] Terminal-Icons..." -ForegroundColor Yellow
try {
    if (Get-Module -ListAvailable -Name Terminal-Icons) {
        Write-Host "  Already installed." -ForegroundColor Green
    } else {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force -SkipPublisherCheck
        Write-Host "  Done." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# [6] zoxide
Write-Host "[6/$totalSteps] zoxide..." -ForegroundColor Yellow
try {
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Write-Host "  Already installed." -ForegroundColor Green
    } else {
        winget install -e --accept-source-agreements --accept-package-agreements ajeetdsouza.zoxide
        Write-Host "  Done." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# [7] fzf + PSFzf
Write-Host "[7/$totalSteps] fzf + PSFzf..." -ForegroundColor Yellow
try {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        winget install -e --accept-source-agreements --accept-package-agreements junegunn.fzf
    }
    if (-not (Get-Module -ListAvailable -Name PSFzf)) {
        Install-Module -Name PSFzf -Repository PSGallery -Force -SkipPublisherCheck
    }
    Write-Host "  Done." -ForegroundColor Green
} catch {
    Write-Error "  Failed: $_"
}

# [8] fastfetch
Write-Host "[8/$totalSteps] fastfetch..." -ForegroundColor Yellow
try {
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        Write-Host "  Already installed." -ForegroundColor Green
    } else {
        winget install -e --accept-source-agreements --accept-package-agreements Fastfetch-cli.Fastfetch
        Write-Host "  Done." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# [9] Git
Write-Host "[9/$totalSteps] Git..." -ForegroundColor Yellow
try {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "  Already installed." -ForegroundColor Green
    } else {
        winget install -e --accept-source-agreements --accept-package-agreements Git.Git
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Host "  Done." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# [10] croc
Write-Host "[10/$totalSteps] croc..." -ForegroundColor Yellow
try {
    if (Get-Command croc -ErrorAction SilentlyContinue) {
        Write-Host "  Already installed." -ForegroundColor Green
    } else {
        winget install -e --accept-source-agreements --accept-package-agreements schollz.croc
        Write-Host "  Done." -ForegroundColor Green
    }
} catch {
    Write-Error "  Failed: $_"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  PROFILE
# ═══════════════════════════════════════════════════════════════════════════════

function Install-Profile {
    param([string]$ProfileDir, [string]$Edition)

    Write-Host ""
    Write-Host "Patching $Edition [$ProfileDir]..." -ForegroundColor Cyan

    if (-not (Test-Path $ProfileDir)) {
        New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
    }

    $profileFile = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"
    $backupFile  = Join-Path $ProfileDir "oldprofile.ps1"

    if (Test-Path $profileFile) {
        $content = Get-Content $profileFile -Raw -ErrorAction SilentlyContinue

        if ($content -match "Fork of ChrisTitusTech/powershell-profile") {
            Write-Host "  Updating existing fork profile." -ForegroundColor DarkGray
        } else {
            # Back up anything else (old wrapper, raw CTT, or unknown profile)
            Write-Host "  Backing up existing profile to [$backupFile]" -ForegroundColor DarkGray
            Copy-Item -Path $profileFile -Destination $backupFile -Force

            # Clean up old wrapper artifacts
            $cttFile = Join-Path $ProfileDir "ctt-profile.ps1"
            if (Test-Path $cttFile) {
                Remove-Item $cttFile -Force
                Write-Host "  Removed leftover ctt-profile.ps1" -ForegroundColor DarkGray
            }
        }
    }

    try {
        Invoke-RestMethod "$($Config.RepoRoot)/Microsoft.PowerShell_profile.ps1" -OutFile $profileFile
        Write-Host "  Profile installed." -ForegroundColor Green
    } catch {
        Write-Error "  Failed to download profile: $_"
        return
    }

    $themeFile = Join-Path $ProfileDir "$($Config.OmpThemeName).omp.json"
    if (-not (Test-Path $themeFile)) {
        try {
            Invoke-RestMethod -Uri $Config.OmpThemeUrl -OutFile $themeFile
            Write-Host "  Theme installed." -ForegroundColor Green
        } catch {
            Write-Warning "  Theme download failed — OMP will use remote fallback."
        }
    }
}

$coreDir    = "$env:USERPROFILE\Documents\PowerShell"
$desktopDir = "$env:USERPROFILE\Documents\WindowsPowerShell"

Install-Profile -ProfileDir $coreDir    -Edition "PowerShell 7+"
Install-Profile -ProfileDir $desktopDir -Edition "Windows PowerShell 5.1"

# ═══════════════════════════════════════════════════════════════════════════════
#  WINDOWS TERMINAL — Flexoki color scheme
# ═══════════════════════════════════════════════════════════════════════════════

$FlexokiScheme = @{
    name = "Flexoki"; background = "#100F0F"; foreground = "#E6E4D9"
    black = "#100F0F"; red = "#AF3029"; green = "#66800B"; yellow = "#C19C00"
    blue = "#205EA6"; purple = "#5E409D"; cyan = "#24837B"; white = "#F2F0E5"
    brightBlack = "#575653"; brightRed = "#D14D41"; brightGreen = "#879A39"; brightYellow = "#D0A215"
    brightBlue = "#4385BE"; brightPurple = "#8B7EC8"; brightCyan = "#3AA99F"; brightWhite = "#FFFCF0"
    cursorColor = "#DAD8CE"; selectionBackground = "#CECDC3"
}

$wtPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

$patchedWT = $false
foreach ($wtPath in $wtPaths) {
    if (-not (Test-Path $wtPath)) { continue }

    Write-Host ""
    Write-Host "Patching Windows Terminal [$wtPath]..." -ForegroundColor Cyan
    try {
        $wt = Get-Content $wtPath -Raw | ConvertFrom-Json

        # Ensure schemes array
        if ($null -eq $wt.PSObject.Properties['schemes']) {
            $wt | Add-Member -MemberType NoteProperty -Name "schemes" -Value @()
        }

        # Add Flexoki if missing
        if (-not ($wt.schemes | Where-Object { $_.name -eq "Flexoki" })) {
            $wt.schemes += [PSCustomObject]$FlexokiScheme
            Write-Host "  Added Flexoki scheme." -ForegroundColor Green
        } else {
            Write-Host "  Flexoki scheme already present." -ForegroundColor Green
        }

        # Set defaults
        if (-not $wt.profiles.defaults) {
            $wt.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value ([PSCustomObject]@{})
        }
        $wt.profiles.defaults | Add-Member -MemberType NoteProperty -Name "colorScheme" -Value "Flexoki" -Force

        # Default terminal size 144x34
        if ($null -eq $wt.PSObject.Properties['initialCols']) {
            $wt | Add-Member -MemberType NoteProperty -Name "initialCols" -Value 144 -Force
        } else {
            $wt.initialCols = 144
        }
        if ($null -eq $wt.PSObject.Properties['initialRows']) {
            $wt | Add-Member -MemberType NoteProperty -Name "initialRows" -Value 34 -Force
        } else {
            $wt.initialRows = 34
        }

        if (-not $wt.profiles.defaults.font) {
            $wt.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value ([PSCustomObject]@{ face = $Config.DefaultFont })
        } else {
            $wt.profiles.defaults.font | Add-Member -MemberType NoteProperty -Name "face" -Value $Config.DefaultFont -Force
        }

        $wt | ConvertTo-Json -Depth 32 | Set-Content $wtPath -Encoding UTF8
        Write-Host "  Windows Terminal patched." -ForegroundColor Green
        $patchedWT = $true
    } catch {
        Write-Warning "  Failed to patch Windows Terminal: $_"
    }
}

if (-not $patchedWT) {
    Write-Host ""
    Write-Host "  Windows Terminal not found — skipping Flexoki." -ForegroundColor DarkGray
}

# ═══════════════════════════════════════════════════════════════════════════════
#  DONE
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  Setup complete." -ForegroundColor Green
Write-Host ""
Write-Host "  Profile directories:" -ForegroundColor White
Write-Host "    $coreDir" -ForegroundColor DarkGray
Write-Host "    $desktopDir" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Commands:" -ForegroundColor White
Write-Host "    Update-Profile     Run this setup again" -ForegroundColor Yellow
Write-Host "    Update-PowerShell  Check for PS updates" -ForegroundColor Yellow
Write-Host "    Show-Help          List all commands" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Restart your terminal to apply changes." -ForegroundColor DarkGray
Write-Host ""
