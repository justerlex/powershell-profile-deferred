<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Fork%20of-ChrisTitusTech%20Powershell%20Profile-orange?style=for-the-badge" alt="CTT Fork">
</p>

# PowerShell Profile

A fork of [ChrisTitusTech's PowerShell profile](https://github.com/ChrisTitusTech/powershell-profile) with performance optimizations and a one-punch setup that installs all dependencies in a single run.

Changes from upstream:
- **No startup network calls** — removed the GitHub connectivity check and automatic update checks that add 200-500ms to every shell launch
- **Deferred loading** — Oh My Posh and PSReadLine load synchronously (~200ms), everything else (Terminal-Icons, zoxide, utility functions) defers via `PowerShell.OnIdle` so the prompt appears instantly
- **PS 5.1 compatible Show-Help** — uses `Write-Host` colors instead of `$PSStyle`
- **Manual updates only** — `Update-Profile` and `Update-PowerShell` are commands you run when you want, not things that surprise you on startup
- **fastfetch** included in the setup

---

## One-Line Install

```powershell
irm "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1" | iex
```

> Run in an **elevated** PowerShell. Works on clean machines and machines with CTT's profile already installed.

---

## What Gets Installed

| Dependency | What it does |
|---|---|
| [Oh My Posh](https://ohmyposh.dev/) | Prompt engine + Cobalt2 theme |
| [CaskaydiaCove NF](https://github.com/ryanoasis/nerd-fonts) | Nerd Font |
| [Chocolatey](https://chocolatey.org/) | Package manager |
| [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | File icons in `ls` output |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| [fzf](https://github.com/junegunn/fzf) + [PSFzf](https://github.com/kelleyma49/PSFzf) | Fuzzy finder + PS integration |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info display |

All steps are idempotent. Safe to re-run, skips anything already installed.

---

## File Layout

After install, each PowerShell profile directory (`Documents\PowerShell` and `Documents\WindowsPowerShell`) contains:

```
PowerShell/
  Microsoft.PowerShell_profile.ps1   <- the profile
  cobalt2.omp.json                   <- Oh My Posh theme
```

---

## Customization

Edit the profile directly — it's yours. Run `Edit-Profile` or `ep` to open it in your configured editor.

If you want to keep personal additions separate from the main profile, create a `profile.ps1` file in the same directory. It gets sourced automatically at the end.

---

## Updating

| Command | What it does |
|---|---|
| `Update-Profile` | Downloads the latest profile from this repo (hash-compares, only overwrites if changed) |
| `Update-PowerShell` | Checks GitHub for the latest PowerShell release and upgrades via winget |

Both are manual — nothing runs automatically on startup.

---

## Credits

- **[ChrisTitusTech](https://github.com/ChrisTitusTech/powershell-profile)** for the original profile

---

<p align="center">
  <sub>MIT License. Do whatever you want with it.</sub>
</p>
