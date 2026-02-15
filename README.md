<div align="center">

[![pwsh 7+](https://img.shields.io/badge/pwsh_7+-4385BE?style=flat-square&logo=powershell&logoColor=white)](#)&nbsp;
[![Flexoki](https://img.shields.io/badge/Flexoki-D0A215?style=flat-square&logo=windowsterminal&logoColor=white)](#)&nbsp;
[![Iosevkata](https://img.shields.io/badge/Iosevkata_NF-879A39?style=flat-square&logo=fontsquirrel&logoColor=white)](#)&nbsp;
[![MIT](https://img.shields.io/badge/MIT-8B7EC8?style=flat-square)](#)

Fork of [ChrisTitusTech/powershell-profile](https://github.com/ChrisTitusTech/powershell-profile)<br>
**Deferred loading · No network on startup · Full dependencies setup**

</div>

---

### What changed

- **Deferred loading** -- Oh My Posh + PSReadLine load synchronously (~200ms), everything else defers via `PowerShell.OnIdle`
- **No network on startup** -- removed connectivity check and auto-update (200-500ms), updates are manual via `Update-Profile` / `Update-PowerShell`

---

### Install

```powershell
irm "https://github.com/justerlex/powershell-profile-deferred/raw/main/setup.ps1" | iex
```

> Elevated PowerShell required. Idempotent -- safe to re-run.

---

### Dependencies

| | Tool | Purpose |
|:---:|---|---|
| <img src="https://img.shields.io/badge/-%234385BE?style=flat-square" height="10"> | [Oh My Posh](https://ohmyposh.dev/) | Prompt engine (Cobalt2 theme) |
| <img src="https://img.shields.io/badge/-%23879A39?style=flat-square" height="10"> | [Iosevkata NF](https://github.com/ningw42/Iosevkata) | Default nerd font |
| <img src="https://img.shields.io/badge/-%23879A39?style=flat-square" height="10"> | [CaskaydiaCove NF](https://github.com/ryanoasis/nerd-fonts) | Fallback nerd font |
| <img src="https://img.shields.io/badge/-%23D0A215?style=flat-square" height="10"> | [Flexoki](https://stephango.com/flexoki) | Color scheme (injected into Windows Terminal) |
| <img src="https://img.shields.io/badge/-%238B7EC8?style=flat-square" height="10"> | [Chocolatey](https://chocolatey.org/) | Package manager |
| <img src="https://img.shields.io/badge/-%238B7EC8?style=flat-square" height="10"> | [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | File icons in `ls` |
| <img src="https://img.shields.io/badge/-%233AA99F?style=flat-square" height="10"> | [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| <img src="https://img.shields.io/badge/-%233AA99F?style=flat-square" height="10"> | [fzf](https://github.com/junegunn/fzf) + [PSFzf](https://github.com/kelleyma49/PSFzf) | Fuzzy finder |
| <img src="https://img.shields.io/badge/-%23D14D41?style=flat-square" height="10"> | [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info |

---

### Layout

```
Documents/PowerShell/
├── Microsoft.PowerShell_profile.ps1
└── cobalt2.omp.json
```

---

### Commands

| Command | Action |
|---|---|
| <kbd>Update-Profile</kbd> | Re-runs setup (dependencies + latest profile) |
| <kbd>Update-PowerShell</kbd> | Checks GitHub for latest PS release, upgrades via winget |
| <kbd>Edit-Profile</kbd> / <kbd>ep</kbd> | Opens the profile in your editor |

Drop a `profile.ps1` next to the main profile for personal additions -- it gets sourced automatically.

---

<div align="center">
<sub>

[ChrisTitusTech](https://github.com/ChrisTitusTech/powershell-profile) · [Flexoki](https://stephango.com/flexoki) · [Iosevkata](https://github.com/ningw42/Iosevkata) · [Oh My Posh](https://ohmyposh.dev/) · MIT

</sub>
</div>
