<p align="center">
  <img src="https://img.shields.io/badge/pwsh-7+-1f1f1f?style=flat-square&logo=powershell&logoColor=5391FE" alt="PowerShell">
  <img src="https://img.shields.io/badge/license-MIT-1f1f1f?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/fork-ChrisTitusTech%2Fpowershell--profile-1f1f1f?style=flat-square" alt="Fork">
</p>

# powershell-profile-deferred

Fork of [ChrisTitusTech/powershell-profile](https://github.com/ChrisTitusTech/powershell-profile). Deferred loading, no startup network calls, full dependencies setup.

## What changed

- **Deferred loading** -- Oh My Posh + PSReadLine load synchronously (~200ms), everything else defers via `PowerShell.OnIdle`
- **No network on startup** -- removed connectivity check and auto-update (200-500ms), updates are manual via `Update-Profile` / `Update-PowerShell`

## Install

```powershell
irm "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1" | iex
```

Requires **elevated** PowerShell. Idempotent -- safe to re-run.

## Dependencies

| Tool | Purpose |
|---|---|
| [Oh My Posh](https://ohmyposh.dev/) | Prompt engine (Cobalt2 theme) |
| [Iosevkata NF](https://github.com/ningw42/Iosevkata) | Default nerd font |
| [CaskaydiaCove NF](https://github.com/ryanoasis/nerd-fonts) | Fallback nerd font |
| [Chocolatey](https://chocolatey.org/) | Package manager |
| [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | File icons in `ls` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| [fzf](https://github.com/junegunn/fzf) + [PSFzf](https://github.com/kelleyma49/PSFzf) | Fuzzy finder |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info |
| [Flexoki](https://stephango.com/flexoki) | Color scheme (injected into Windows Terminal) |

## Layout

```
Documents/PowerShell/
  Microsoft.PowerShell_profile.ps1
  cobalt2.omp.json
```

## Updating

| Command | Action |
|---|---|
| `Update-Profile` | Re-runs setup (dependencies + latest profile) |
| `Update-PowerShell` | Checks GitHub for latest PS release, upgrades via winget |

## Customizing

`Edit-Profile` / `ep` opens the profile in your editor. Drop a `profile.ps1` next to it for personal additions -- it gets sourced automatically.

## Credits

- [ChrisTitusTech](https://github.com/ChrisTitusTech/powershell-profile) -- original profile
- [Flexoki](https://stephango.com/flexoki) -- color scheme
- [Iosevkata](https://github.com/ningw42/Iosevkata) -- default font
- [Oh My Posh](https://ohmyposh.dev/) -- prompt engine

<p align="center"><sub>MIT</sub></p>
