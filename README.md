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
| `.config/uwsm/`, `.config/systemd/user/` | Session environment and desktop services |
| `.gnupg/` | Optional GnuPG display and agent preferences |
| `scripts/`, `docs/` | Installer, checks, utility guide, and cleanup decisions |

## Desktop

[Desktop guide](docs/desktop.md): Hyprland shortcuts, UWSM service setup,
brightness keys, OLED idle timers, and recovery to a plain Hyprland session.

## Shell and editor

Zsh keeps `steeef`, vi editing, fzf history, completions, and syntax highlighting.
Optional NVM/RVM and language integrations load when installed. Vim/Neovim share
comma leader, `jj` for Escape, relative numbers, four-space indentation, and the
editing/Git plugins installed by `make vim-plugins`. Multiple selections use
Neovim's `multicursor.nvim` with Ctrl+I / Ctrl+Y / Ctrl+B / Escape. Tmux uses Ctrl+Z as prefix,
`|`/`-` splits, vi copy mode, and numbering from 1.

The useful Git/GitHub, VM, GPG, container, password-menu, and keyboard-light tools
were retained and adapted. See [the utility guide](docs/tools.md) for commands,
optional dependencies, and preview/apply behavior. The unused Irssi and
Rainbowstream configurations were archived outside the repository.

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
`~/.local/state/dotfiles/backups/20261028-201644-lean-cleanup/`.
[Cleanup decisions](docs/cleanup.md) explain what was removed and what was retained.
