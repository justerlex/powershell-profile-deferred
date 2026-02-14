### Deferred CTT Profile Wrapper
### Loads oh-my-posh + PSReadLine synchronously, then sources the full CTT profile
### in a background runspace so the prompt appears instantly.
### https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/

# ═══════════════════════════════════════════════════════════════════════════════
#  SYNCHRONOUS - runs immediately
# ═══════════════════════════════════════════════════════════════════════════════

$global:ProfileStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix ..." -f $PSVersionTable.PSVersion.ToString()

function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return [Environment]::GetFolderPath("MyDocuments") + "\PowerShell"
    } elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        return [Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell"
    } else {
        Write-Error "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
        return $null
    }
}

# ── Oh-My-Posh ──
$localThemePath = Join-Path (Get-ProfileDir) "cobalt2.omp.json"
if (Test-Path $localThemePath) {
    oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
} else {
    oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json" | Invoke-Expression
}

# Save the oh-my-posh prompt before CTT overwrites it
$global:DeferredWrapperPrompt = (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue).ScriptBlock

# ── PSReadLine ──
if ($host.Name -eq 'ConsoleHost') {
    $PSReadLineOptions = @{
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
        $PSReadLineOptions['PredictionSource']    = 'History'
        $PSReadLineOptions['PredictionViewStyle'] = 'ListView'
    }

    Set-PSReadLineOption @PSReadLineOptions

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

# ═══════════════════════════════════════════════════════════════════════════════
#  DEFERRED - CTT profile loads in a background runspace
# ═══════════════════════════════════════════════════════════════════════════════

$global:ProfileStopwatch.Stop()
$syncMs = [math]::Round($global:ProfileStopwatch.Elapsed.TotalMilliseconds)

# Show boot time on the same line as the PowerShell version banner.
# Falls back to a separate line if cursor manipulation isn't supported.
$bootStatusText = "boot ${syncMs}ms | Type 'Show-Help' for commands"
$bootStatusShown = $false
try {
    $rawUi = $Host.UI.RawUI
    $cursor = $rawUi.CursorPosition
    $targetY = $cursor.Y - 1
    $targetX = $rawUi.WindowSize.Width - $bootStatusText.Length - 1

    if ($targetY -ge 0 -and $targetX -ge 0) {
        $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($targetX, $targetY)
        Write-Host "boot " -NoNewline -ForegroundColor Cyan
        Write-Host "${syncMs}ms" -NoNewline -ForegroundColor DarkGray
        Write-Host " | " -NoNewline -ForegroundColor DarkGray
        Write-Host "Type " -NoNewline -ForegroundColor DarkGray
        Write-Host "'Show-Help'" -NoNewline -ForegroundColor Yellow
        Write-Host " for commands" -NoNewline -ForegroundColor DarkGray
        $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $cursor.Y)
        $bootStatusShown = $true
    }
} catch { }

if (-not $bootStatusShown) {
    Write-Host "  boot " -NoNewline -ForegroundColor Cyan
    Write-Host "${syncMs}ms" -NoNewline -ForegroundColor DarkGray
    Write-Host " | " -NoNewline -ForegroundColor DarkGray
    Write-Host "Type " -NoNewline -ForegroundColor DarkGray
    Write-Host "'Show-Help'" -NoNewline -ForegroundColor Yellow
    Write-Host " for commands" -ForegroundColor DarkGray
}

$global:CttProfilePath = Join-Path (Split-Path $PROFILE) "ctt-profile.ps1"

$Deferred = {

    # Overrides: must exist before sourcing CTT so its Get-Command checks find them
    function Get-Theme_Override { }             # oh-my-posh already loaded
    function Set-PredictionSource_Override { }   # PSReadLine already configured

    # Update-Profile targets ctt-profile.ps1 instead of $PROFILE (our wrapper)
    function Update-Profile_Override {
        try {
            $url = "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
            $oldhash = Get-FileHash $global:CttProfilePath
            Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
            $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
            if ($newhash.Hash -ne $oldhash.Hash) {
                Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $global:CttProfilePath -Force
                Write-Host "CTT profile updated. Restart your shell to reflect changes." -ForegroundColor Magenta
            } else {
                Write-Host "CTT profile is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Error "Unable to check for CTT profile updates: $_"
        } finally {
            Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
        }
    }

    function Update-Wrapper {
        try {
            $url = "https://raw.githubusercontent.com/justerlex/powershell-profile-deferred/main/Microsoft.PowerShell_profile.ps1"
            $oldhash = Get-FileHash $PROFILE
            Invoke-RestMethod $url -OutFile "$env:temp/deferred-wrapper.ps1"
            $newhash = Get-FileHash "$env:temp/deferred-wrapper.ps1"
            if ($newhash.Hash -ne $oldhash.Hash) {
                Copy-Item -Path "$env:temp/deferred-wrapper.ps1" -Destination $PROFILE -Force
                Write-Host "Deferred wrapper updated. Restart your shell to reflect changes." -ForegroundColor Magenta
            } else {
                Write-Host "Deferred wrapper is up to date." -ForegroundColor Green
            }
        } catch {
            Write-Error "Unable to check for wrapper updates: $_"
        } finally {
            Remove-Item "$env:temp/deferred-wrapper.ps1" -ErrorAction SilentlyContinue
        }
    }

    # Source CTT profile with Write-Host suppressed to prevent background output
    # stomping the terminal. Functions defined during sourcing resolve Write-Host
    # at call time, so they'll find the real cmdlet when invoked later.
    if (Test-Path $global:CttProfilePath) {
        try {
            function Write-Host { }
            . $global:CttProfilePath
        } finally {
            if (Test-Path Function:\Write-Host) {
                Remove-Item Function:\Write-Host -ErrorAction SilentlyContinue
            }
        }

        if ($global:DeferredWrapperPrompt) {
            Set-Item Function:\prompt -Value $global:DeferredWrapperPrompt
        }
    } else {
        Write-Warning "CTT profile not found at $global:CttProfilePath. Did you rename it?"
    }

    $global:ProfileFullyLoaded = $true

    # Title: ... -> * -> clean
    $currentTitle = $Host.UI.RawUI.WindowTitle -replace ' \.\.\.$', ''
    $Host.UI.RawUI.WindowTitle = "$currentTitle *"
    Start-Sleep -Seconds 1
    $Host.UI.RawUI.WindowTitle = $currentTitle
}

# ═══════════════════════════════════════════════════════════════════════════════
#  LAUNCH - fsackur's SessionState + Runspace technique
# ═══════════════════════════════════════════════════════════════════════════════

# https://seeminglyscience.github.io/powershell/2017/09/30/invocation-operators-states-and-scopes
$GlobalState = [psmoduleinfo]::new($false)
$GlobalState.SessionState = $ExecutionContext.SessionState

# JediTerm (IntelliJ) creates runspaces fine but the background session-state
# injection silently fails, so functions never arrive. Load synchronously there.
if ($env:TERMINAL_EMULATOR -eq 'JetBrains-JediTerm') {
    . $Deferred
    Remove-Variable Deferred
} else {
    $Wrapper = {
        # 200ms delay avoids PSReadLine timing issues (crashes, missing highlighting)
        Start-Sleep -Milliseconds 200
        . $GlobalState { . $Deferred; Remove-Variable Deferred }
    }
    try {
        $Runspace = [runspacefactory]::CreateRunspace($Host)
        $Powershell = [powershell]::Create($Runspace)
        $Runspace.Open()
        $Runspace.SessionStateProxy.PSVariable.Set('GlobalState', $GlobalState)

        # Share ArgumentCompleter dictionaries so Register-ArgumentCompleter
        # calls from CTT (git, npm, dotnet etc.) work across runspaces
        $Private = [Reflection.BindingFlags]'Instance, NonPublic'
        $ContextField = [Management.Automation.EngineIntrinsics].GetField('_context', $Private)
        $Context = $ContextField.GetValue($ExecutionContext)

        $ContextCACProperty = $Context.GetType().GetProperty('CustomArgumentCompleters', $Private)
        $ContextNACProperty = $Context.GetType().GetProperty('NativeArgumentCompleters', $Private)
        $CAC = $ContextCACProperty.GetValue($Context)
        $NAC = $ContextNACProperty.GetValue($Context)

        if ($null -eq $CAC) {
            $CAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
            $ContextCACProperty.SetValue($Context, $CAC)
        }
        if ($null -eq $NAC) {
            $NAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
            $ContextNACProperty.SetValue($Context, $NAC)
        }

        $RSEngineField = $Runspace.GetType().GetField('_engine', $Private)
        $RSEngine = $RSEngineField.GetValue($Runspace)
        $EngineContextField = $RSEngine.GetType().GetFields($Private) | Where-Object { $_.FieldType.Name -eq 'ExecutionContext' }
        $RSContext = $EngineContextField.GetValue($RSEngine)

        $ContextCACProperty.SetValue($RSContext, $CAC)
        $ContextNACProperty.SetValue($RSContext, $NAC)

        $null = $Powershell.AddScript($Wrapper.ToString()).BeginInvoke()
    } catch {
        . $Deferred
    }
}
