# setpanel

Open Windows Terminal with N panes arranged in a balanced grid, in one command.

```cmd
setpanel -ps 3 -bash 2
```

→ 5-pane grid (3 PowerShell + 2 Git Bash) opens in your current Windows Terminal window.

## Why

Composing `wt split-pane ...` chains by hand is tedious — calculating split fractions,
remembering focus directions, picking the right shell. `setpanel` takes
`-ps N -bash N` flags and lays out a true balanced grid for you (every pane equal size).

## Requirements

- **Windows 10/11** with [Windows Terminal](https://github.com/microsoft/terminal) installed (`wt.exe` on PATH)
- **PowerShell 5.1+** (built-in on Windows). PowerShell 7+ (`pwsh.exe`) is auto-detected and preferred if installed.
- **Git Bash** *(optional, only required for `-bash` panes)*. Default location: `C:\Program Files\Git\bin\bash.exe`
- **WSL** *(optional, only required for `-wsl` panes)*. `wsl.exe` launches your default distro.

## Install

1. Clone or download this repository:
   ```cmd
   git clone https://github.com/ishizakahiroshi/setpanel.git
   ```
2. Keep the downloaded `setpanel` folder together. The `.bat` launchers call the `.ps1` scripts in the same folder, so do not move only one file by itself.
3. *(Optional)* Add the folder to your `PATH` so you can call `setpanel` from any working directory.

## Which file should I use?

Start with `setpanel-menu.bat` if you are not sure. It opens a keyboard-driven menu and lets you pick a preset or working directory.

Use these files from the same folder. You can move or copy the whole folder anywhere you like, but keep the files together.

| File | Use when |
|---|---|
| `setpanel-menu.bat` | You want the easiest interactive menu |
| `setpanel.bat` | You want to run a command directly, like `setpanel -ps 2 -bash 2` |
| `install-shortcuts.ps1` | You want Desktop shortcuts for common layouts |
| `setpanel.ps1` | You are editing the main layout logic |
| `setpanel-menu.ps1` | You are editing the interactive menu logic |

## Usage

```cmd
setpanel                     # 4 PowerShell panes (2x2 grid) — default
setpanel -d C:\work -ps 4    # Open panes in C:\work
setpanel -ps 3               # 3 PowerShell panes
setpanel -ps 6               # 6 panes (2x3 grid)
setpanel -ps 2 -bash 2       # Mixed: 2 pwsh + 2 bash (2x2)
setpanel -ps 2 -wsl 2        # Mixed: 2 pwsh + 2 WSL
setpanel -ps 4 -bash 2       # 6 panes total (2x3)
```

- `-d DIR`, `-dir DIR`, or `-cwd DIR` sets the working directory for all panes
- `-ps N` adds N PowerShell panes (1-12)
- `-bash N` adds N Git Bash panes (1-12)
- `-wsl N` adds N WSL panes (1-12)
- Total panes capped at **12**
- Without `-d`, panes open in the current working directory of the calling shell

## Interactive menu

Run `setpanel-menu.bat` (or double-click it) to pick a preset with the keyboard:

```
> 1) ps 2 (side by side)
  2) ps 3
  3) ps 4 (2x2 grid)
  4) ps 6 (2x3 grid)
  5) ps 2 + bash 2
  6) ps 3 + bash 3
  7) Custom args
  8) Change working directory
  0) cancel
```

Use Up/Down to move, Enter to choose, or press 1-8 as shortcuts. The menu opens panes in the current directory by default; choose `Change working directory` to launch somewhere else.

## Desktop shortcuts

Generate ready-to-use `.lnk` shortcuts so you can launch presets with a single click:

```powershell
.\install-shortcuts.ps1
```

Creates 6 shortcuts on your Desktop:

| Shortcut | Launches |
|---|---|
| `setpanel-ps2.lnk` | `setpanel -ps 2` |
| `setpanel-ps4.lnk` | `setpanel -ps 4` |
| `setpanel-ps6.lnk` | `setpanel -ps 6` |
| `setpanel-mixed.lnk` | `setpanel -ps 2 -bash 2` |
| `setpanel-wsl.lnk` | `setpanel -wsl 2` |
| `setpanel-menu.lnk` | Opens the interactive menu |

Install to a different location (e.g. Start Menu):

```powershell
.\install-shortcuts.ps1 -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\setpanel"
```

Each shortcut's working directory defaults to `$env:USERPROFILE`. Override with `-WorkingDirectory <path>` or edit the shortcut's properties afterward.

## Configuration

The Git Bash path is hardcoded near the top of `setpanel.ps1`:

```powershell
$BASH = 'C:\Program Files\Git\bin\bash.exe'
```

Edit it if your Git Bash lives elsewhere. If `bash.exe` is not found at this path, `-bash` panes fall back to PowerShell with a warning.
WSL panes use `wsl.exe --cd <dir>` and launch your default distro.

## Other platforms

setpanel is Windows-specific — it drives `wt.exe`, which does not exist on Linux or macOS.
If you need similar grid layouts on other platforms, consider:

- [tmux](https://github.com/tmux/tmux) — classic terminal multiplexer
- [zellij](https://zellij.dev/) — modern alternative with declarative layouts
- [wezterm](https://wezfurlong.org/wezterm/) — GPU-accelerated terminal with full CLI control

## License

MIT — see [LICENSE](LICENSE).

---

[日本語版 README はこちら](README.ja.md)
