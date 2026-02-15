<div align="left">

[![pwsh 7+](https://img.shields.io/badge/pwsh_7+-4385BE?style=flat-square&logo=powershell&logoColor=white)](#)&nbsp;
[![Flexoki](https://img.shields.io/badge/Flexoki-D0A215?style=flat-square&logo=windowsterminal&logoColor=white)](#)&nbsp;
[![Iosevkata](https://img.shields.io/badge/Iosevkata_NF-879A39?style=flat-square&logo=fontsquirrel&logoColor=white)](#)&nbsp;
[![MIT](https://img.shields.io/badge/MIT-8B7EC8?style=flat-square)](#)

</div>

<div align="center">
  
```
-------------------------------------------------------------------------------------
  ╺┳┓┏━╸┏━╸┏━╸┏━┓┏━┓┏━╸╺┳┓   ┏━┓┏━┓╻ ╻┏━╸┏━┓┏━┓╻ ╻┏━╸╻  ╻     ┏━┓┏━┓┏━┓┏━╸╻╻  ┏━╸
   ┃┃┣╸ ┣╸ ┣╸ ┣┳┛┣┳┛┣╸  ┃┃   ┣━┛┃ ┃┃╻┃┣╸ ┣┳┛┗━┓┣━┫┣╸ ┃  ┃     ┣━┛┣┳┛┃ ┃┣╸ ┃┃  ┣╸ 
  ╺┻┛┗━╸╹  ┗━╸╹┗╸╹┗╸┗━╸╺┻┛   ╹  ┗━┛┗┻┛┗━╸╹┗╸┗━┛╹ ╹┗━╸┗━╸┗━╸   ╹  ╹┗╸┗━┛╹  ╹┗━╸┗━╸
-------------------------------------------------------------------------------------
```

</div>

<div align="right">
  
**Deferred loading · No network on startup · Full dependencies setup**<br>
Fork of [ChrisTitusTech/powershell-profile](https://github.com/ChrisTitusTech/powershell-profile)

</div>

---

### What changed

⚡ **Deferred loading** — Oh My Posh + PSReadLine load synchronously, everything else defers via `PowerShell.OnIdle`<br>
🔒 **Manual updates only** — Removed connectivity check and auto-update, saving ~200–500ms<br>
🎨 **Dependencies & styling** — Opinionated styling + all dependencies (like `fzf`)<br>

<div align="right">
<kbd>> start typing right away, text will show once everything loads</kbd>
</div>

---

### Install

```powershell
irm "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1" | iex
```

<div align="right">
<sub>Elevated PowerShell required.</sub>
</div>

---

### Bundled

| | Tool | Purpose |
|:---:|---|---|
| <img src="https://img.shields.io/badge/-%234385BE?style=flat-square" height="10"> | [Windows Terminal](https://github.com/microsoft/terminal) | Terminal emulator |
| <img src="https://img.shields.io/badge/-%234385BE?style=flat-square" height="10"> | [PowerShell 7](https://github.com/PowerShell/PowerShell) | Shell |
| <img src="https://img.shields.io/badge/-%234385BE?style=flat-square" height="10"> | [Oh My Posh](https://ohmyposh.dev/) | Prompt engine (Cobalt2 theme) |
| <img src="https://img.shields.io/badge/-%23879A39?style=flat-square" height="10"> | [Iosevkata NF](https://github.com/ningw42/Iosevkata) | Default nerd font |
| <img src="https://img.shields.io/badge/-%23879A39?style=flat-square" height="10"> | [CaskaydiaCove NF](https://github.com/ryanoasis/nerd-fonts) | Fallback nerd font |
| <img src="https://img.shields.io/badge/-%23D0A215?style=flat-square" height="10"> | [Flexoki](https://stephango.com/flexoki) | Color scheme (injected into Windows Terminal) |
| <img src="https://img.shields.io/badge/-%238B7EC8?style=flat-square" height="10"> | [Chocolatey](https://chocolatey.org/) | Package manager |
| <img src="https://img.shields.io/badge/-%238B7EC8?style=flat-square" height="10"> | [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | File icons in `ls` |
| <img src="https://img.shields.io/badge/-%233AA99F?style=flat-square" height="10"> | [Git](https://git-scm.com/) | Version control |
| <img src="https://img.shields.io/badge/-%233AA99F?style=flat-square" height="10"> | [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| <img src="https://img.shields.io/badge/-%233AA99F?style=flat-square" height="10"> | [fzf](https://github.com/junegunn/fzf) + [PSFzf](https://github.com/kelleyma49/PSFzf) | Fuzzy finder |
| <img src="https://img.shields.io/badge/-%23D14D41?style=flat-square" height="10"> | [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info |
| <img src="https://img.shields.io/badge/-%23D14D41?style=flat-square" height="10"> | [croc](https://github.com/schollz/croc) | File transfer |
| <img src="https://img.shields.io/badge/-%23D14D41?style=flat-square" height="10"> | [pomo](https://github.com/Bahaaio/pomo) | Pomodoro  |

---

### Troubleshooting

```powershell
[System.Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", "C:\Program Files\Git\usr\bin\file.exe", "User")
# Example of adding path to git's file(1), for proper Yazi mime typing
```

<div align="right">
<sub>In case you need to add something to PATH.</sub>
</div>
<br>

```cmd
powershell -Command "Start-Process PowerShell -Verb RunAs"
```

<div align="right">
<sub>Run elevated  PowerShell.</sub>
</div>
<br>

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force # Allow scripts for current window [safe]
Set-ExecutionPolicy Unrestricted # Allow scripts in general [not-so-safe]
```

<div align="right">
<sub>ExecutionPolicies fix.</sub>
</div>

---

### Settings

```
Documents/PowerShell/
├── Microsoft.PowerShell_profile.ps1   # main profile (aliases, functions, deferred loading)
└── cobalt2.omp.json                   # Oh My Posh prompt theme
```

---

### Commands

| Command | Action |
|---|---|
| <kbd>Update-Profile</kbd> | Re-runs setup (dependencies + latest profile) |
| <kbd>Update-PowerShell</kbd> | Checks GitHub for latest PS release |
| <kbd>Edit-Profile</kbd> / <kbd>ep</kbd> | Opens the profile in your editor |



<div align="right">
  
  <sub>Drop a `profile.ps1` next to the main profile for personal additions -- it gets sourced automatically.</sub>
  
</div>


---

<div align="center">
<sub>

[ChrisTitusTech](https://github.com/ChrisTitusTech/powershell-profile) · [Flexoki](https://stephango.com/flexoki) · [Iosevkata](https://github.com/ningw42/Iosevkata) · [Oh My Posh](https://ohmyposh.dev/) · MIT

</sub>
</div>
