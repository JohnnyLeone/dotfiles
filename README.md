# Dotfiles

Arch Linux desktop: Hyprland (Lua), ashell, Vicinae, Kitty, Zsh, Neovim, and tmux.
The setup includes OLED protection and the keyboard workflow carried over from i3/Sway.

## Install

```sh
sudo pacman -S --needed zsh zsh-completions zsh-syntax-highlighting tmux fzf grim slurp
# Optional framework; skip if it is already installed:
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.local/share/oh-my-zsh
cd ~/dotfiles
make dry-run
make install
make check
make vim-plugins
```

The installer links individual files and user commands into your home directory,
backing up anything it replaces. `make dry-run` lists those changes first.
Runtime programs such as Hyprland, ashell, Vicinae, Kitty, and Neovim must already
be installed. The installer does not configure system services or install packages.

Install a single tool/config without replacing other files:

```sh
python3 scripts/dotfiles.py install --only .local/bin/passmenu
```

Kitty starts Zsh. Run `exec zsh` in an existing terminal. To use it for console
and SSH logins too, run `chsh -s /usr/bin/zsh`, then log in again.

## Contents

| Path | Purpose |
| --- | --- |
| `.config/hypr/` | Native Lua compositor config, hypridle, hyprlock |
| `.config/ashell/` | Status bar and AMD GPU usage helper |
| `.config/kitty/`, `.config/nvim/`, `.config/vicinae/` | Current application settings |
| `.config/gtk-3.0/`, `.gtkrc-2.0` | Adwaita, Noto Sans, and cursor settings for GTK apps |
| `.zshrc`, `.aliases`, `.functions`, `.exports`, `.path` | Shell, completion, aliases, utilities |
| `.dockerfunc` | Three portable container helpers; no desktop-app wrappers |
| `.vimrc`, `.tmux.conf`, `.gitconfig`, `gitignore`, `.inputrc` | Editor, terminal, Git, and readline preferences |
| `bin/` | Desktop helpers and reusable command-line tools |
| `.gnupg/`, `.irssi/`, `.rainbow_config.json` | Optional preferences, themes, and plugins |
| `scripts/`, `docs/` | Installer, checks, utility guide, and cleanup decisions |

## Hyprland shortcuts

Super is the Windows/logo key.

| Shortcut | Action |
| --- | --- |
| Super+Enter (also Super+Q) | Kitty terminal |
| Super+Shift+Q | Close window |
| Super+D | Vicinae launcher |
| Super+C | Vicinae clipboard history |
| Super+P | Current Bitwarden app |
| Super+H/J/K/L or arrows | Focus left/down/up/right |
| Super+Shift+H/J/K/L or arrows | Move window |
| Super+1…0 | Workspaces 1…10 |
| Super+Shift+1…0 | Move window to workspace |
| Super+B / Super+V | Next split right / below |
| Super+E | Toggle split direction |
| Super+F | Fullscreen |
| Super+Shift+Space | Toggle floating |
| Super+Space | Switch focus between tiled and floating windows |
| Super+W | Toggle a tabbed window group |
| Super+S or Super+Tab | Next window in group |
| Super+Shift+Tab | Previous window in group |
| Super+Shift+S | Pin a floating window |
| Super+R, then H/J/K/L or arrows | Resize; Enter/Escape finishes |
| Super+Minus / Super+Shift+Minus | Show scratchpad / send window there |
| Super+Ctrl+L | Lock and pause media |
| Super+Ctrl+B | Hide/show ashell |
| Super+Shift+Enter | Open home directory in the default file manager |
| Super+Shift+C | Validate and reload Hyprland |
| Super+Shift+E | Logout confirmation; Enter confirms, Escape cancels |
| Super+Ctrl+Shift+Left/Right | Move workspace to another monitor |
| Print / Shift+Print / Super+Print | Screenshot selection / all screens / active window |
| Super+T | Play the clipboard URL with mpv |
| Alt+Shift | Switch EU/German keyboard layouts; Caps still acts as Escape |

Screenshots are saved under the XDG Pictures directory in `Screenshots/` and copied
to the clipboard. Volume, brightness, media keys, gestures, and mouse dragging are
retained. Clipboard history uses Vicinae's [documented deeplink](https://docs.vicinae.com/deeplinks).

Hyprland groups approximate tabbed containers; dwindle has no exact equivalent
for i3 stacked containers or parent-container focus. Edit
`.config/hypr/hyprland.lua`, then use Super+Shift+C to validate and reload.
Hypridle and hyprlock are separate programs and retain their `.conf` format.

## Status bar and OLED protection

Ashell shows CPU/RAM, CPU temperature, root disk usage, network IP, GPU usage,
media, volume, network name, battery/VPN/tray controls, and weather in Celsius.
Click the EU/DE layout label to switch layouts. The mode indicator appears during
resize/logout confirmation. The screenshot button uses left/middle/right click
for all screens / active window / a selection. Right-click the clock to toggle seconds.

| Idle time | Action |
| --- | --- |
| 15 seconds without pointer activity | Hide the pointer |
| 60 seconds without input | Hide ashell; restore on activity |
| 180 seconds without input | Lock |
| 240 seconds without input | Turn displays off; wake on activity |

Video/presentation inhibitors prevent automatic locking and display-off. The
bar-only timeout still hides static UI, and preserves a manually hidden bar.
Use Super+Ctrl+B to control visibility. Black desktop/terminal backgrounds,
dimmer bar text, and a subdued lock-screen clock reduce static bright content.
Kitty applies config changes to new terminals or after Ctrl+Shift+F5.

Use moderate SDR brightness and the monitor's own OLED Care protections, including
screen movement, logo dimming, proximity detection, and automatic pixel cleaning.
Keep power connected while cleaning runs. These measures reduce exposure rather
than guarantee prevention. [ASUS model guidance](https://rog.asus.com/us/monitors/27-to-31-5-inches/rog-swift-oled-pg32ucdm-gen3-pg32ucdm3/).

## Shell and editor

Zsh keeps `steeef`, vi editing, fzf history, completions, and syntax highlighting.
Optional NVM/RVM and language integrations load when installed. Vim/Neovim share
comma leader, `jj` for Escape, relative numbers, four-space indentation, and the
editing/Git plugins installed by `make vim-plugins`. Tmux uses Ctrl+Z as prefix,
`|`/`-` splits, vi copy mode, and numbering from 1.

The useful Git/GitHub, VM, GPG, container, password-menu, and keyboard-light tools
were retained and adapted. See [the utility guide](docs/tools.md) for commands,
optional dependencies, and preview/apply behavior. IRC themes/plugins are retained
for optional use, independent of the window manager.

Local overrides: `~/.extra`, `~/.gitconfig.local`, `~/.tmux.conf.local`, and
`~/.config/kitty/local.conf`. The historical Git identity is retained; set signing
preferences in `~/.gitconfig.local` after importing the corresponding key.
GnuPG preferences are opt-in, and key material is never installed from this repo.

## Backups and review

Installer backups are in `~/.local/state/dotfiles/backups/`, with a `manifest.json`
for every install that changed links. Undo a specific installation with:

```sh
python3 ~/dotfiles/scripts/dotfiles.py restore ~/.local/state/dotfiles/backups/BACKUP_NAME
hyprctl reload
```

Restoration refuses to overwrite later replacement files. The cleanup recovery
copy, including the complete pre-cleanup repo snapshot, is at
`~/.local/state/dotfiles/backups/20261026-234714-cleanup/`.
[Cleanup decisions](docs/cleanup.md) explain what was removed and what was retained.
