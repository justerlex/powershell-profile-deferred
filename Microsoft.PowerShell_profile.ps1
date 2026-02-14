### PowerShell Profile — Fork of ChrisTitusTech/powershell-profile
### https://github.com/justerlex/powershell-profile-deferred
###
### Single-file fork with performance optimizations. Prompt-critical stuff loads
### first (oh-my-posh, PSReadLine), heavier modules and utilities follow.

# ═══════════════════════════════════════════════════════════════════════════════
#  FAST PATH — prompt-critical, runs before you can start typing
# ═══════════════════════════════════════════════════════════════════════════════

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Opt-out of telemetry if running as SYSTEM
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Admin check + window title
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# ── Oh-My-Posh ──
function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return [Environment]::GetFolderPath("MyDocuments") + "\PowerShell"
    } else {
        return [Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell"
    }
}

$localThemePath = Join-Path (Get-ProfileDir) "cobalt2.omp.json"
if (Test-Path $localThemePath) {
    oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
} else {
    oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json" | Invoke-Expression
}

# ── PSReadLine ──
if ($host.Name -eq 'ConsoleHost') {
    # Compat wrapper: strips PredictionSource/PredictionViewStyle on PS 5.1
    function Set-PSReadLineOptionsCompat {
        param([hashtable]$Options)
        if ($PSVersionTable.PSEdition -eq "Core") {
            Set-PSReadLineOption @Options
        } else {
            $SafeOptions = $Options.Clone()
            $SafeOptions.Remove('PredictionSource')
            $SafeOptions.Remove('PredictionViewStyle')
            Set-PSReadLineOption @SafeOptions
        }
    }

    $PSReadLineOptions = @{
        EditMode                      = 'Windows'
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        Colors                        = @{
            Command   = '#87CEEB'   # SkyBlue
            Parameter = '#98FB98'   # PaleGreen
            Operator  = '#FFB6C1'   # LightPink
            Variable  = '#DDA0DD'   # Plum
            String    = '#FFDAB9'   # PeachPuff
            Number    = '#B0E0E6'   # PowderBlue
            Type      = '#F0E68C'   # Khaki
            Comment   = '#D3D3D3'   # LightGray
            Keyword   = '#8367c7'   # Violet
            Error     = '#FF6347'   # Tomato
        }
        PredictionSource              = 'History'
        PredictionViewStyle           = 'ListView'
        BellStyle                     = 'None'
    }
    Set-PSReadLineOptionsCompat -Options $PSReadLineOptions

    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
        $hasSensitive = $sensitive | Where-Object { $line -match $_ }
        return ($null -eq $hasSensitive)
    }

    if ($PSVersionTable.PSEdition -eq "Core") {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    }
    Set-PSReadLineOption -MaximumHistoryCount 10000
}

# ── Boot time display ──
$stopwatch.Stop()
$syncMs = [math]::Round($stopwatch.Elapsed.TotalMilliseconds)

$bootStatusText = "boot ${syncMs}ms | Type 'Show-Help' for commands"
$bootInline = $false
try {
    $rawUi = $Host.UI.RawUI
    $cursor = $rawUi.CursorPosition
    $targetY = $cursor.Y - 1
    $targetX = $rawUi.WindowSize.Width - $bootStatusText.Length - 1
    if ($targetY -ge 0 -and $targetX -ge 0) {
        $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($targetX, $targetY)
        $bootInline = $true
    }
} catch { }

if (-not $bootInline) { Write-Host "  " -NoNewline }
Write-Host "boot " -NoNewline -ForegroundColor Cyan
Write-Host "${syncMs}ms" -NoNewline -ForegroundColor DarkGray
Write-Host " | " -NoNewline -ForegroundColor DarkGray
Write-Host "Type " -NoNewline -ForegroundColor DarkGray
Write-Host "'Show-Help'" -NoNewline -ForegroundColor Yellow
Write-Host " for commands" -NoNewline -ForegroundColor DarkGray
if ($bootInline) {
    $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $cursor.Y)
} else {
    Write-Host
}

# ═══════════════════════════════════════════════════════════════════════════════
#  MODULES
# ═══════════════════════════════════════════════════════════════════════════════

if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  UPDATE FUNCTIONS (manual only — no auto-check on startup)
# ═══════════════════════════════════════════════════════════════════════════════

function Update-Profile {
    try {
        $url = "https://raw.githubusercontent.com/justerlex/powershell-profile-deferred/main/Microsoft.PowerShell_profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
            Write-Host "Profile has been updated. Please restart your shell to reflect changes." -ForegroundColor Magenta
        } else {
            Write-Host "Profile is up to date." -ForegroundColor Green
        }
    } catch {
        Write-Error "Unable to check for profile updates: $_"
    } finally {
        Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
    }
}

function Update-PowerShell {
    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
            Write-Host "PowerShell has been updated. Please restart your shell to reflect changes." -ForegroundColor Magenta
        } else {
            Write-Host "Your PowerShell is up to date." -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
#  UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
elseif (Test-CommandExists pvim) { 'pvim' }
elseif (Test-CommandExists vim) { 'vim' }
elseif (Test-CommandExists vi) { 'vi' }
elseif (Test-CommandExists code) { 'code' }
elseif (Test-CommandExists codium) { 'codium' }
elseif (Test-CommandExists notepad++) { 'notepad++' }
elseif (Test-CommandExists sublime_text) { 'sublime_text' }
else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR

function Edit-Profile { vim $PROFILE }
Set-Alias -Name ep -Value Edit-Profile

function Invoke-Profile {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        Write-Host "Note: Some Oh My Posh/PSReadLine errors are expected in PowerShell 5. The profile still works fine." -ForegroundColor Yellow
    }
    & $PROFILE
}

function touch($file) { "" | Out-File $file -Encoding ASCII }

function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function pubip { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# WinUtil
function winutil { Invoke-Expression (Invoke-RestMethod https://christitus.com/win) }
function winutildev { Invoke-Expression (Invoke-RestMethod https://christitus.com/windev) }

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}
Set-Alias -Name su -Value admin

function uptime {
    try {
        $dateFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.ShortDatePattern
        $timeFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.LongTimePattern

        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $lastBoot = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)
            $lastBoot = $bootTime.ToString("$dateFormat $timeFormat")
        } else {
            $lastBoot = (Get-Uptime -Since).ToString("$dateFormat $timeFormat")
            $bootTime = [System.DateTime]::ParseExact($lastBoot, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
        }

        $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBoot]"
        Write-Host "System started on: $formattedBootTime" -ForegroundColor DarkGray

        $uptime = (Get-Date) - $bootTime
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds) -ForegroundColor Blue
    } catch {
        Write-Error "An error occurred while retrieving system uptime."
    }
}

function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

function hb {
    if ($args.Length -eq 0) {
        Write-Error "No file path specified."
        return
    }
    $FilePath = $args[0]
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }
    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Set-Clipboard $url
        Write-Output "$url copied to clipboard."
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}

function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df { get-volume }

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path
    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath
        if ($item.PSIsContainer) {
            $parentPath = $item.Parent.FullName
        } else {
            $parentPath = $item.DirectoryName
        }
        $shell = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)
        if ($item) {
            $shellItem.InvokeVerb('delete')
            Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
        } else {
            Write-Host "Error: Could not find the item '$fullPath' to trash."
        }
    } else {
        Write-Host "Error: Item '$fullPath' does not exist."
    }
}

function Clear-Cache {
    Write-Host "Clearing cache..." -ForegroundColor Cyan
    Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cache clearing completed." -ForegroundColor Green
}

# Navigation Shortcuts
function docs {
    $docs = if(([Environment]::GetFolderPath("MyDocuments"))) {([Environment]::GetFolderPath("MyDocuments"))} else {$HOME + "\Documents"}
    Set-Location -Path $docs
}
function dtop {
    $dtop = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Documents"}
    Set-Location -Path $dtop
}

# Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem | Format-Table -AutoSize }
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

# Git Shortcuts
function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m "$m" }
function gpush { git push }
function gpull { git pull }
function g { __zoxide_z github }
function gcl { git clone "$args" }
function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking
function flushdns {
    Clear-DnsClientCache
    Write-Host "DNS has been flushed"
}

# Clipboard
function cpy { Set-Clipboard $args[0] }
function pst { Get-Clipboard }

# ═══════════════════════════════════════════════════════════════════════════════
#  ARGUMENT COMPLETERS
# ═══════════════════════════════════════════════════════════════════════════════

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $customCompletions = @{
        'git' = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
        'npm' = @('install', 'start', 'run', 'test', 'build')
        'deno' = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
    }
    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock $scriptblock

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

# ═══════════════════════════════════════════════════════════════════════════════
#  INTEGRATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# Help
function Show-Help {
    Write-Host ""
    Write-Host "PowerShell Profile Help" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Edit-Profile / ep" -ForegroundColor Green -NoNewline
    Write-Host " - Open profile in editor" -ForegroundColor Gray
    Write-Host "  Update-Profile" -ForegroundColor Green -NoNewline
    Write-Host " - Pull latest profile from repo" -ForegroundColor Gray
    Write-Host "  Update-PowerShell" -ForegroundColor Green -NoNewline
    Write-Host " - Check for PowerShell updates" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Git Shortcuts" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Yellow
    Write-Host "  gs" -ForegroundColor Green -NoNewline
    Write-Host " - git status" -ForegroundColor Gray
    Write-Host "  ga" -ForegroundColor Green -NoNewline
    Write-Host " - git add ." -ForegroundColor Gray
    Write-Host "  gc <msg>" -ForegroundColor Green -NoNewline
    Write-Host " - git commit -m" -ForegroundColor Gray
    Write-Host "  gcl <repo>" -ForegroundColor Green -NoNewline
    Write-Host " - git clone" -ForegroundColor Gray
    Write-Host "  gcom <msg>" -ForegroundColor Green -NoNewline
    Write-Host " - git add . && git commit -m" -ForegroundColor Gray
    Write-Host "  gpush" -ForegroundColor Green -NoNewline
    Write-Host " - git push" -ForegroundColor Gray
    Write-Host "  gpull" -ForegroundColor Green -NoNewline
    Write-Host " - git pull" -ForegroundColor Gray
    Write-Host "  lazyg <msg>" -ForegroundColor Green -NoNewline
    Write-Host " - add, commit, push" -ForegroundColor Gray
    Write-Host "  g" -ForegroundColor Green -NoNewline
    Write-Host " - cd to github directory" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Utilities" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Yellow
    Write-Host "  cpy <text>" -ForegroundColor Green -NoNewline
    Write-Host " - Copy to clipboard" -ForegroundColor Gray
    Write-Host "  pst" -ForegroundColor Green -NoNewline
    Write-Host " - Paste from clipboard" -ForegroundColor Gray
    Write-Host "  df" -ForegroundColor Green -NoNewline
    Write-Host " - Disk volumes" -ForegroundColor Gray
    Write-Host "  docs" -ForegroundColor Green -NoNewline
    Write-Host " - cd to Documents" -ForegroundColor Gray
    Write-Host "  dtop" -ForegroundColor Green -NoNewline
    Write-Host " - cd to Desktop" -ForegroundColor Gray
    Write-Host "  export <n> <v>" -ForegroundColor Green -NoNewline
    Write-Host " - Set env variable" -ForegroundColor Gray
    Write-Host "  ff <name>" -ForegroundColor Green -NoNewline
    Write-Host " - Find files recursively" -ForegroundColor Gray
    Write-Host "  flushdns" -ForegroundColor Green -NoNewline
    Write-Host " - Clear DNS cache" -ForegroundColor Gray
    Write-Host "  grep <rx> [dir]" -ForegroundColor Green -NoNewline
    Write-Host " - Search text in files" -ForegroundColor Gray
    Write-Host "  hb <file>" -ForegroundColor Green -NoNewline
    Write-Host " - Upload to hastebin" -ForegroundColor Gray
    Write-Host "  head <path> [n]" -ForegroundColor Green -NoNewline
    Write-Host " - First n lines (default 10)" -ForegroundColor Gray
    Write-Host "  tail <path> [n]" -ForegroundColor Green -NoNewline
    Write-Host " - Last n lines (default 10)" -ForegroundColor Gray
    Write-Host "  k9 <name>" -ForegroundColor Green -NoNewline
    Write-Host " - Kill process by name" -ForegroundColor Gray
    Write-Host "  la" -ForegroundColor Green -NoNewline
    Write-Host " - List files" -ForegroundColor Gray
    Write-Host "  ll" -ForegroundColor Green -NoNewline
    Write-Host " - List files (incl. hidden)" -ForegroundColor Gray
    Write-Host "  mkcd <dir>" -ForegroundColor Green -NoNewline
    Write-Host " - Create and cd into directory" -ForegroundColor Gray
    Write-Host "  nf <name>" -ForegroundColor Green -NoNewline
    Write-Host " - Create new file" -ForegroundColor Gray
    Write-Host "  pgrep <name>" -ForegroundColor Green -NoNewline
    Write-Host " - List processes by name" -ForegroundColor Gray
    Write-Host "  pkill <name>" -ForegroundColor Green -NoNewline
    Write-Host " - Kill processes by name" -ForegroundColor Gray
    Write-Host "  pubip" -ForegroundColor Green -NoNewline
    Write-Host " - Show public IP" -ForegroundColor Gray
    Write-Host "  sed <f> <find> <rep>" -ForegroundColor Green -NoNewline
    Write-Host " - Replace text in file" -ForegroundColor Gray
    Write-Host "  sysinfo" -ForegroundColor Green -NoNewline
    Write-Host " - System information" -ForegroundColor Gray
    Write-Host "  touch <file>" -ForegroundColor Green -NoNewline
    Write-Host " - Create empty file" -ForegroundColor Gray
    Write-Host "  trash <path>" -ForegroundColor Green -NoNewline
    Write-Host " - Move to Recycle Bin" -ForegroundColor Gray
    Write-Host "  unzip <file>" -ForegroundColor Green -NoNewline
    Write-Host " - Extract zip" -ForegroundColor Gray
    Write-Host "  uptime" -ForegroundColor Green -NoNewline
    Write-Host " - System uptime" -ForegroundColor Gray
    Write-Host "  which <name>" -ForegroundColor Green -NoNewline
    Write-Host " - Show command path" -ForegroundColor Gray
    Write-Host "  winutil" -ForegroundColor Green -NoNewline
    Write-Host " - Chris Titus WinUtil" -ForegroundColor Gray
    Write-Host "  winutildev" -ForegroundColor Green -NoNewline
    Write-Host " - Chris Titus WinUtil (dev)" -ForegroundColor Gray
    Write-Host "  Clear-Cache" -ForegroundColor Green -NoNewline
    Write-Host " - Clear temp/prefetch/IE cache" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Use 'Show-Help' to display this help message." -ForegroundColor Magenta
    Write-Host ""
}

# Source user customizations if present
if (Test-Path "$PSScriptRoot\profile.ps1") {
    . "$PSScriptRoot\profile.ps1"
}

Write-Host "Use 'Show-Help' to display help" -ForegroundColor Yellow
