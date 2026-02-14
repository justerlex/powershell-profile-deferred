### Deferred CTT Profile Wrapper
### Uses fsackur's runspace technique to load the CTT profile asynchronously
### https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/

# ═══════════════════════════════════════════════════════════════════════════════
#  SYNCHRONOUS. runs immediately, gets you a working prompt ASAP
# ═══════════════════════════════════════════════════════════════════════════════

$global:ProfileStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Encoding. MUST be main thread, cannot be deferred
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Telemetry opt-out (same as CTT's, only when running as system)
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Admin check + window title. you want this on screen immediately
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix [loading]" -f $PSVersionTable.PSVersion.ToString()

# Helper (same as CTT's, needed for theme path)
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

# ── Oh-My-Posh ── Your prompt. Non-negotiable sync.
$localThemePath = Join-Path (Get-ProfileDir) "cobalt2.omp.json"
if (Test-Path $localThemePath) {
    oh-my-posh init pwsh --config $localThemePath | Invoke-Expression
} else {
    # Fallback: remote theme (only on first run before theme is downloaded)
    oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json" | Invoke-Expression
}

# Preserve the oh-my-posh prompt so deferred CTT loading can't replace it.
$global:DeferredWrapperPrompt = (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue).ScriptBlock

# ── PSReadLine ── Full config matching CTT's setup so you feel no difference from keystroke one
if ($host.Name -eq 'ConsoleHost') {
    # Replicate CTT's pastel color scheme and settings (lines 573-613 of the original)
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
        BellStyle                     = 'None'
    }

    # Desktop compat: strip unsupported keys
    if ($PSVersionTable.PSEdition -eq "Core") {
        $PSReadLineOptions['PredictionSource']    = 'History'
        $PSReadLineOptions['PredictionViewStyle'] = 'ListView'
    }

    Set-PSReadLineOption @PSReadLineOptions

    # Key handlers. identical to CTT
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

    # Filter sensitive commands from history
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
        $hasSensitive = $sensitive | Where-Object { $line -match $_ }
        return ($null -eq $hasSensitive)
    }

    # Final prediction source. Core gets HistoryAndPlugin, Desktop gets History
    if ($PSVersionTable.PSEdition -eq "Core") {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    }
    Set-PSReadLineOption -MaximumHistoryCount 10000
}

# ═══════════════════════════════════════════════════════════════════════════════
#  DEFERRED. the entire CTT profile loads in a background runspace
# ═══════════════════════════════════════════════════════════════════════════════

# Boot sequence display
$global:ProfileStopwatch.Stop()
$syncMs = [math]::Round($global:ProfileStopwatch.Elapsed.TotalMilliseconds)

# Try to render helper text on the right side of the startup banner line.
# If host/cursor APIs aren't available, fall back to the normal second-line output.
$bootStatusText = "boot ${syncMs}ms | Type 'Show-Help' for commands"
$bootStatusShown = $false

try {
    $rawUi = $Host.UI.RawUI
    $cursor = $rawUi.CursorPosition
    $windowWidth = $rawUi.WindowSize.Width
    $targetY = $cursor.Y - 1
    $targetX = $windowWidth - $bootStatusText.Length - 1

    if ($targetY -ge 0 -and $targetX -ge 0) {
        $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($targetX, $targetY)
        Write-Host "boot " -NoNewline -ForegroundColor Cyan
        Write-Host "$syncMs" -NoNewline -ForegroundColor Gray
        Write-Host "ms" -NoNewline -ForegroundColor DarkGray
        Write-Host " | " -NoNewline -ForegroundColor DarkGray
        Write-Host "Type " -NoNewline -ForegroundColor DarkGray
        Write-Host "'Show-Help'" -NoNewline -ForegroundColor Yellow
        Write-Host " for commands" -NoNewline -ForegroundColor DarkGray
        $rawUi.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $cursor.Y)
        $bootStatusShown = $true
    }
} catch {
    $bootStatusShown = $false
}

if (-not $bootStatusShown) {
    Write-Host "boot " -NoNewline -ForegroundColor Cyan
    Write-Host "$syncMs" -NoNewline -ForegroundColor Gray
    Write-Host "ms" -NoNewline -ForegroundColor DarkGray
    Write-Host " | " -NoNewline -ForegroundColor DarkGray
    Write-Host "Type " -NoNewline -ForegroundColor DarkGray
    Write-Host "'Show-Help'" -NoNewline -ForegroundColor Yellow
    Write-Host " for commands" -ForegroundColor DarkGray
}


# Path to the renamed CTT profile
$global:CttProfilePath = Join-Path (Split-Path $PROFILE) "ctt-profile.ps1"

# The deferred scriptblock. runs in the global SessionState via background runspace
$Deferred = {

    # ── Overrides ──
    # These MUST be defined before sourcing CTT so its Get-Command checks find them.

    # We already init'd oh-my-posh synchronously. don't let CTT do it again
    function Get-Theme_Override { }

    # We already configured PSReadLine. don't let CTT reconfigure/conflict
    function Set-PredictionSource_Override { }

    # Redirect Update-Profile to target ctt-profile.ps1 instead of $PROFILE (our wrapper)
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

    # ── Source the full CTT profile ──
    # Everything: Terminal-Icons, GitHub connectivity check, zoxide, all 50+ functions,
    # argument completers, chocolatey profile. Loads here in the background.
    # Functions become available incrementally as each line executes.
    #
    # IMPORTANT: We shadow Write-Host with a no-op during sourcing to prevent
    # background output from stomping the terminal while you're typing.
    # Functions DEFINED during sourcing (uptime, flushdns, etc.) won't break
    # because PowerShell resolves command names at call time, not definition time.
    # When you run 'uptime' later, it finds the real Write-Host cmdlet.
    if (Test-Path $global:CttProfilePath) {
        function Write-Host { }
        . $global:CttProfilePath
        Remove-Item Function:\Write-Host

        # CTT defines its own prompt. Restore the sync oh-my-posh prompt.
        if ($global:DeferredWrapperPrompt) {
            Set-Item Function:\prompt -Value $global:DeferredWrapperPrompt
        }
    } else {
        Write-Warning "CTT profile not found at $global:CttProfilePath. Did you rename it?"
    }

    # ── YOUR PERSONAL ADDITIONS ──
    # Anything you add here also loads deferred. Put your most-used stuff first
    # so it's available soonest (the scriptblock runs top-to-bottom).
    #
    # Examples:
    #   Import-Module posh-git
    #   function myalias { ... }
    #   Set-Alias -Name k -Value kubectl

    # Signal that everything is loaded
    $global:ProfileFullyLoaded = $true

    # Flash completion in window title (non-destructive, never stomps your prompt)
    # ⏳ → ✓ → clean
    $currentTitle = $Host.UI.RawUI.WindowTitle -replace ' \[loading\]$', ''
    $Host.UI.RawUI.WindowTitle = "$currentTitle [ready]"
    Start-Sleep -Seconds 2
    $Host.UI.RawUI.WindowTitle = $currentTitle
}


# ═══════════════════════════════════════════════════════════════════════════════
#  DEFERRED LOADING ENGINE. fsackur's SessionState + Runspace technique
# ═══════════════════════════════════════════════════════════════════════════════

# Capture the global session state so the background runspace can inject into it
# https://seeminglyscience.github.io/powershell/2017/09/30/invocation-operators-states-and-scopes
$GlobalState = [psmoduleinfo]::new($false)
$GlobalState.SessionState = $ExecutionContext.SessionState

# Create a runspace attached to $Host (needed for Write-Host etc. in deferred code)
$Runspace = [runspacefactory]::CreateRunspace($Host)
$Powershell = [powershell]::Create($Runspace)
$Runspace.Open()
$Runspace.SessionStateProxy.PSVariable.Set('GlobalState', $GlobalState)

# ── ArgumentCompleter Reflection Hack ──
# Without this, Register-ArgumentCompleter calls in CTT's profile (git, npm, deno, dotnet)
# would silently fail because completers are stored on the ExecutionContext, not SessionState.
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

# Wire the runspace's ExecutionContext to share the same ArgumentCompleter dictionaries
$RSEngineField = $Runspace.GetType().GetField('_engine', $Private)
$RSEngine = $RSEngineField.GetValue($Runspace)
$EngineContextField = $RSEngine.GetType().GetFields($Private) | Where-Object { $_.FieldType.Name -eq 'ExecutionContext' }
$RSContext = $EngineContextField.GetValue($RSEngine)

$ContextCACProperty.SetValue($RSContext, $CAC)
$ContextNACProperty.SetValue($RSContext, $NAC)

# ── Launch ──
$Wrapper = {
    # The 200ms sleep is NOT optional. Without it you get:
    #   - Occasional crashes
    #   - Prompt not rendering
    #   - Syntax highlighting missing
    # This is a PSReadLine timing issue. 200ms is generous but non-blocking (background thread).
    Start-Sleep -Milliseconds 200

    . $GlobalState { . $Deferred; Remove-Variable Deferred }
}

$null = $Powershell.AddScript($Wrapper.ToString()).BeginInvoke()

# ═══════════════════════════════════════════════════════════════════════════════
#  DONE. prompt is live. CTT functions arrive within ~1 second.
# ═══════════════════════════════════════════════════════════════════════════════
