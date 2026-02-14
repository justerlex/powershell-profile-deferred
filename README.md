<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Works%20With-ChrisTitusTech%20Powershell%20Profile-orange?style=for-the-badge" alt="CTT Compatible">
</p>

# ⚡ Deferred PowerShell Profile

A performance wrapper for [ChrisTitusTech's PowerShell profile](https://github.com/ChrisTitusTech/powershell-profile) that makes your prompt appear instantly while everything else loads in the background. Also handles a complete one-punch dependency install: fonts, tools, modules, etc...

Your prompt shows up in **~200ms** instead of ~1-2 seconds. Everything else loads in a background runspace within about a second. 

The technique comes from [fsackur's deferred loading approach](https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/) using [SeeminglyScience's SessionState trick](https://seeminglyscience.github.io/powershell/2017/09/30/invocation-operators-states-and-scopes). You keep all CTT profile functionality, just wrapped to load smarter.

---

## 🚀 One-Line Install

```powershell
irm "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1" | iex
```

> Run in an **elevated** PowerShell. Works on clean machines and machines with CTT's profile already installed.

---

> Note: startup status text in the wrapper uses ASCII-only characters so the profile parses correctly in Windows PowerShell 5.1 even when files are saved without a UTF BOM.

## 📦 What Gets Installed

The installer handles everything in one shot.

| Dependency | What it does |
|---|---|
| [Oh My Posh](https://ohmyposh.dev/) | Prompt engine + Cobalt2 theme |
| [CaskaydiaCove NF](https://github.com/ryanoasis/nerd-fonts) | Nerd Font (CTT default) |
| [Meslo NF](https://github.com/ryanoasis/nerd-fonts) | Nerd Font (OMP recommended) |
| [Chocolatey](https://chocolatey.org/) | Package manager |
| [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | File icons in `ls` output |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| [fzf](https://github.com/junegunn/fzf) + [PSFzf](https://github.com/kelleyma49/PSFzf) | Fuzzy finder + PS integration |

All steps are idempotent. Safe to re-run, skips anything already installed.

---

## 🗂️ File Layout

After install, each PowerShell profile directory (`Documents\PowerShell` and `Documents\WindowsPowerShell`) contains:

```
📁 PowerShell/
├── Microsoft.PowerShell_profile.ps1   ← deferred wrapper (this new one, never overwritten by CTT)
├── ctt-profile.ps1                    ← CTT's full profile (auto-updates via Update-Profile)
└── cobalt2.omp.json                   ← Oh My Posh theme
```

`Update-Profile` still works as expected. It pulls the latest CTT code into `ctt-profile.ps1` and the wrapper stays untouched.

---

## ⚙️ How It Works

**Loaded synchronously** (~200ms, before you can start typing):
- `[console]::OutputEncoding` (must be main thread)
- Oh My Posh prompt
- Full PSReadLine config (colors, key handlers, predictions)
- Admin check + window title

**Loaded in background runspace** (~1-2 seconds):
- The entire CTT profile: Terminal-Icons, zoxide, all utility functions, argument completers
- GitHub connectivity check + update logic
- Chocolatey profile

Three `_Override` functions prevent double-initialization:
- `Get-Theme_Override` since OMP already started
- `Set-PredictionSource_Override` since PSReadLine is already configured
- `Update-Profile_Override` redirects updates to `ctt-profile.ps1`

---

## 🔧 Customization

Add your personal functions inside the `YOUR PERSONAL ADDITIONS` section in the deferred block. Items near the top of the block become available soonest (it executes top-to-bottom).

CTT's full `_Override` system is preserved. See [his README](https://github.com/ChrisTitusTech/powershell-profile#customize-this-profile) for the list of overrideable variables and functions.

---

## ⚠️ VS Code Users

Add this to your VS Code settings if you use the integrated terminal:

```json
"terminal.integrated.shellIntegration.enabled": false
```

Shell integration hooks conflict with the background runspace.

---

## 🙏 Credits

- **[ChrisTitusTech](https://github.com/ChrisTitusTech/powershell-profile)** for the profile that makes PowerShell not suck
- **[fsackur](https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/)** for the deferred loading technique
- **[SeeminglyScience](https://seeminglyscience.github.io/powershell/2017/09/30/invocation-operators-states-and-scopes)** for the SessionState trick that makes it all possible

---

<p align="center">
  <sub>MIT License. Do whatever you want with it.</sub>
</p>
