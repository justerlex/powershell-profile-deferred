### PowerShell Profile — Fork of ChrisTitusTech/powershell-profile
### https://github.com/justerlex/powershell-profile-deferred
###
### Single-file fork with deferred loading. Prompt-critical stuff (OMP,
### PSReadLine) loads synchronously. Everything else defers via OnIdle so
### the prompt appears in ~200ms while modules and functions load after.

# ═══════════════════════════════════════════════════════════════════════════════
#  SYNCHRONOUS — runs before the prompt appears (~200ms)
# ═══════════════════════════════════════════════════════════════════════════════

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Opt out of telemetry if running as SYSTEM
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Window title
$adminSuffix = if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix ..." -f $PSVersionTable.PSVersion.ToString()

# ── Oh My Posh ──
$localThemePath = Join-Path (Split-Path $PROFILE) "cobalt2.omp.json"
if (Test-Path $localThemePath) {
    oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
} else {
    oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json" | Invoke-Expression
}

# ── PSReadLine ──
if ($host.Name -eq 'ConsoleHost') {
    $PSRLOptions = @{
        EditMode                      = 'Windows'
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        Colors                        = @{
            Command   = '#87CEEB'
            Parameter = '#98FB98'
            Operator  = '#FFB6C1'
            Variable  = '#DDA0DD'
            String    = '#FFDAB9'
            Number    = '#B0E0E6'
            Type      = '#F0E68C'
            Comment   = '#D3D3D3'
            Keyword   = '#8367c7'
            Error     = '#FF6347'
        }
        BellStyle                     = 'None'
    }
    if ($PSVersionTable.PSEdition -eq "Core") {
        $PSRLOptions['PredictionSource'] = 'HistoryAndPlugin'
        $PSRLOptions['PredictionViewStyle'] = 'ListView'
    }
    Set-PSReadLineOption @PSRLOptions

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

    Set-PSReadLineOption -MaximumHistoryCount 10000
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
        return $null -eq ($sensitive | Where-Object { $line -match $_ })
    }
}

# ── Boot time display ──
$stopwatch.Stop()
$syncMs = [math]::Round($stopwatch.Elapsed.TotalMilliseconds)

$bootText = "boot ${syncMs}ms | Type 'Show-Help' for commands"
try {
    $rawUi = $Host.UI.RawUI
    $cursor = $rawUi.CursorPosition
    $targetY = $cursor.Y - 1
    $targetX = $rawUi.WindowSize.Width - $bootText.Length - 1
    if ($targetY -ge 0 -and $targetX -ge 0) {
        $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($targetX, $targetY)
        Write-Host "boot " -NoNewline -ForegroundColor Cyan
        Write-Host "${syncMs}ms" -NoNewline -ForegroundColor DarkGray
        Write-Host " | Type " -NoNewline -ForegroundColor DarkGray
        Write-Host "Show-Help" -NoNewline -ForegroundColor Yellow
        Write-Host " for commands" -ForegroundColor DarkGray
        $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $cursor.Y)
    }
} catch { }

# ═══════════════════════════════════════════════════════════════════════════════
#  DEFERRED — runs via OnIdle in the main session state after the prompt appears
# ═══════════════════════════════════════════════════════════════════════════════

$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {

    # ── Modules ──
    Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue

    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path $ChocolateyProfile) {
        Import-Module $ChocolateyProfile
    }

    # ── Update ──
    function global:Update-Profile {
        Write-Host "Running setup (installs dependencies + updates profile)..." -ForegroundColor Cyan
        Invoke-Expression (Invoke-RestMethod "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1")
    }

    function global:Update-PowerShell {
        try {
            Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
            $currentVersion = $PSVersionTable.PSVersion.ToString()
            $latestVersion = (Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest").tag_name.Trim('v')
            if ($currentVersion -lt $latestVersion) {
                Write-Host "Updating PowerShell..." -ForegroundColor Yellow
                Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
                Write-Host "PowerShell updated. Restart your shell to reflect changes." -ForegroundColor Magenta
            } else {
                Write-Host "PowerShell is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to update PowerShell: $_"
        }
    }

    # ── Editor ──
    $global:EDITOR = foreach ($cmd in 'nvim','pvim','vim','vi','code','codium','notepad++','sublime_text','notepad') {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { $cmd; break }
    }
    Set-Alias -Name vim -Value $global:EDITOR -Scope Global

    function global:Edit-Profile { vim $PROFILE }
    Set-Alias -Name ep -Value Edit-Profile -Scope Global

    function global:Invoke-Profile { & $PROFILE }

    # ── Utility Functions ──
    function global:touch($file) { "" | Out-File $file -Encoding ASCII }
    function global:ff($name) {
        Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName }
    }
    function global:pubip { (Invoke-WebRequest http://ifconfig.me/ip).Content }
    function global:wtr { curl "wttr.in" }
    Set-Alias -Name inv -Value Invoke-Item -Scope Global
    function global:winutil { Invoke-Expression (Invoke-RestMethod https://christitus.com/win) }
    function global:winutildev { Invoke-Expression (Invoke-RestMethod https://christitus.com/windev) }

    function global:admin {
        if ($args.Count -gt 0) {
            Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $($args -join ' ')"
        } else {
            Start-Process wt -Verb runAs
        }
    }
    Set-Alias -Name su -Value admin -Scope Global

    function global:uptime {
        try {
            if ($PSVersionTable.PSVersion.Major -eq 5) {
                $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject win32_operatingsystem).LastBootUpTime)
            } else {
                $bootTime = Get-Uptime -Since
            }
            Write-Host "System started on: $($bootTime.ToString('dddd, MMMM dd, yyyy HH:mm:ss'))" -ForegroundColor DarkGray
            $up = (Get-Date) - $bootTime
            Write-Host ("Uptime: {0} days, {1} hours, {2} minutes" -f $up.Days, $up.Hours, $up.Minutes) -ForegroundColor Blue
        } catch {
            Write-Error "Failed to retrieve system uptime."
        }
    }

    function global:unzip($file) {
        $fullFile = (Get-ChildItem -Path $pwd -Filter $file | Select-Object -First 1).FullName
        Expand-Archive -Path $fullFile -DestinationPath $pwd
    }

    function global:hb {
        if ($args.Length -eq 0) { Write-Error "No file path specified."; return }
        if (-not (Test-Path $args[0])) { Write-Error "File does not exist."; return }
        try {
            $response = Invoke-RestMethod -Uri "http://bin.christitus.com/documents" -Method Post -Body (Get-Content $args[0] -Raw) -ErrorAction Stop
            $url = "http://bin.christitus.com/$($response.key)"
            Set-Clipboard $url
            Write-Output "$url copied to clipboard."
        } catch {
            Write-Error "Failed to upload: $_"
        }
    }

    function global:grep($regex, $dir) {
        if ($dir) { Get-ChildItem $dir | Select-String $regex }
        else { $input | Select-String $regex }
    }
    function global:df { Get-Volume }
    function global:sed($file, $find, $replace) { (Get-Content $file).Replace($find, $replace) | Set-Content $file }
    function global:which($name) { Get-Command $name | Select-Object -ExpandProperty Definition }
    function global:export($name, $value) { Set-Item -Force -Path "env:$name" -Value $value }
    function global:pkill($name) { Get-Process $name -ErrorAction SilentlyContinue | Stop-Process }
    function global:pgrep($name) { Get-Process $name }

    function global:head { param($Path, $n = 10) Get-Content $Path -Head $n }
    function global:tail { param($Path, $n = 10, [switch]$f = $false) Get-Content $Path -Tail $n -Wait:$f }

    function global:nf { param($name) New-Item -ItemType File -Path . -Name $name }
    function global:mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

    function global:trash($path) {
        $fullPath = (Resolve-Path $path).Path
        if (-not (Test-Path $fullPath)) { Write-Host "Error: '$fullPath' does not exist."; return }
        $item = Get-Item $fullPath
        $parentPath = if ($item.PSIsContainer) { $item.Parent.FullName } else { $item.DirectoryName }
        $shell = New-Object -ComObject 'Shell.Application'
        $shell.NameSpace($parentPath).ParseName($item.Name).InvokeVerb('delete')
        Write-Host "Item '$fullPath' moved to Recycle Bin."
    }

    function global:Clear-Cache {
        Write-Host "Clearing cache..." -ForegroundColor Cyan
        @("$env:SystemRoot\Prefetch\*", "$env:SystemRoot\Temp\*", "$env:TEMP\*", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*") |
            ForEach-Object { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "Cache cleared." -ForegroundColor Green
    }

    # Navigation
    function global:docs { Set-Location ([Environment]::GetFolderPath("MyDocuments")) }
    function global:dtop { Set-Location ([Environment]::GetFolderPath("Desktop")) }

    # Process
    function global:k9 { Stop-Process -Name $args[0] }

    # Listing
    function global:la { Get-ChildItem | Format-Table -AutoSize }
    function global:ll { Get-ChildItem -Force | Format-Table -AutoSize }

    # Git
    function global:gs { git status }
    function global:ga { git add . }
    function global:gc { param($m) git commit -m "$m" }
    function global:gpush { git push }
    function global:gpull { git pull }
    function global:g { __zoxide_z github }
    function global:gcl { git clone "$args" }
    function global:gcom { git add .; git commit -m "$args" }
    function global:lazyg { git add .; git commit -m "$args"; git push }

    # System
    function global:sysinfo { Get-ComputerInfo }
    function global:flushdns { Clear-DnsClientCache; Write-Host "DNS flushed." }
    function global:cpy { Set-Clipboard $args[0] }
    function global:pst { Get-Clipboard }
    function global:ffe { fastfetch }

    # ── Argument Completers ──
    $scriptblock = {
        param($wordToComplete, $commandAst, $cursorPosition)
        $completions = @{
            'git'  = @('status','add','commit','push','pull','clone','checkout')
            'npm'  = @('install','start','run','test','build')
            'deno' = @('run','compile','bundle','test','lint','fmt','cache','info','doc','upgrade')
        }
        $cmd = $commandAst.CommandElements[0].Value
        if ($completions.ContainsKey($cmd)) {
            $completions[$cmd] | Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        }
    }
    Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock $scriptblock

    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition $commandAst.ToString() |
            ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
    }

    # ── zoxide ──
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    }

    # ── Help ──
    function global:Show-Help {
        Write-Host ""
        Write-Host "PowerShell Profile Help" -ForegroundColor Cyan
        Write-Host "=======================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Edit-Profile / ep" -ForegroundColor Green -NoNewline
        Write-Host " - Open profile in editor" -ForegroundColor Gray
        Write-Host "  Update-Profile" -ForegroundColor Green -NoNewline
        Write-Host " - Run setup (dependencies + profile)" -ForegroundColor Gray
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
        Write-Host "  croc" -ForegroundColor Green -NoNewline
        Write-Host " - File transfer (croc)" -ForegroundColor Gray
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
        Write-Host "  ffe" -ForegroundColor Green -NoNewline
        Write-Host " - System info (fastfetch)" -ForegroundColor Gray
        Write-Host "  flushdns" -ForegroundColor Green -NoNewline
        Write-Host " - Clear DNS cache" -ForegroundColor Gray
        Write-Host "  grep <rx> [dir]" -ForegroundColor Green -NoNewline
        Write-Host " - Search text in files" -ForegroundColor Gray
        Write-Host "  hb <file>" -ForegroundColor Green -NoNewline
        Write-Host " - Upload to hastebin" -ForegroundColor Gray
        Write-Host "  inv <path>" -ForegroundColor Green -NoNewline
        Write-Host " - Open file/folder (Invoke-Item)" -ForegroundColor Gray
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
        Write-Host "  wtr" -ForegroundColor Green -NoNewline
        Write-Host " - Weather in terminal (wttr.in)" -ForegroundColor Gray
        Write-Host "  Clear-Cache" -ForegroundColor Green -NoNewline
        Write-Host " - Clear temp/prefetch/IE cache" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Use 'Show-Help' to display this help message." -ForegroundColor Magenta
        Write-Host ""
    }

    # Source user customizations if present
    $customProfile = Join-Path (Split-Path $PROFILE) "profile.ps1"
    if (Test-Path $customProfile) { . $customProfile }

    # Title: ... -> ok -> clean
    $currentTitle = $Host.UI.RawUI.WindowTitle -replace ' \.\.\.$', ''
    $Host.UI.RawUI.WindowTitle = "$currentTitle ok"
    Start-Sleep -Milliseconds 500
    $Host.UI.RawUI.WindowTitle = $currentTitle
}
