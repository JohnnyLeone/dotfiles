# Reusable tools

`make install` links these commands into `~/.local/bin`. To add only one command:

```sh
python3 scripts/dotfiles.py install --only .local/bin/openprs
```

Optional dependencies are needed only when you use the corresponding tool.
No VM, container, remote repository, keyserver, or system service is changed during
installation or checks.

| Command | Purpose | Optional dependency |
| --- | --- | --- |
| `openprs [OWNER]` | List open PRs in an owner's repositories; defaults to the authenticated account | GitHub CLI `gh`, authenticated |
| `updateforks [OWNER] [--apply]` | Preview fork synchronization; apply uses fast-forward updates | `gh`, authenticated |
| `update-mirrors [DIRECTORY] [--apply]` | Preview mirror-repository updates directly under a directory | Git |
| `createvm NAME INSTALLER.iso [--apply]` | Preview/create a native per-user VM, without the former Docker bridge setup | `virt-install`, libvirt, QEMU for `--apply` |
| `cleanup-non-running-images [--apply]` | Show container disk usage; apply prunes unreferenced images with Docker's confirmation | Docker |
| `gitdate [DATE]` | Print UTC commit-date exports; sourcing sets them in Bash/Zsh | GNU date |
| `keyboard-backlight up/down/total/off/info` | Control a detected keyboard LED device | `brightnessctl`, compatible hardware |
| `keysign FINGERPRINT...` | Fingerprint review and interactive GPG signing; export/publish are explicit choices | GnuPG |
| `passmenu [--type]` | Choose a password-store entry with Vicinae and copy/type its first line | `pass`; Vicinae/bemenu; optional `wtype` for typing |
| `check-kconfig [FILE] [--flag NAME ...]` | Read-only kernel-option inspection | `zgrep` from gzip |
| `dotfiles-hypr` / `dotfiles-bar` | Existing screenshots, locking, reload, and bar visibility | Current desktop components |

## Git and GitHub

The GitHub tools use `gh` authentication or its supported token environment
variables; they no longer parse HTTP pagination by hand or assume SSH keys exist.
`openprs` defaults to at most 100 results; additional `gh search prs` options can
be appended. `updateforks` lists up to 1000 non-archived forks.
See [PR search](https://cli.github.com/manual/gh_search_prs) and
[repository sync](https://cli.github.com/manual/gh_repo_sync).

`updateforks` previews by default and never adds `--force`. Divergent forks fail
instead of having their commits overwritten. `update-mirrors` also previews by
default and requires a separate, explicit origin `pushurl`. A mirror push replaces
the destination refs, so use it only for destinations intended to be exact mirrors.

Use `gcutc` as an alternative to `gc` to commit with a UTC timezone. For explicitly
setting a particular commit instant:

```sh
source ~/.local/bin/gitdate '2026-10-26 12:30:00 +0100'
git commit
unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
```

## Virtual machines and containers

`createvm` uses `qemu:///session`, user-mode networking, and disk images under
`${XDG_DATA_HOME:-~/.local/share}/libvirt/images/`. Its defaults are 2 vCPUs,
2048 MiB RAM, and a 16 GiB qcow2 disk; override with `VM_VCPUS`, `VM_MEMORY`, and
`VM_DISK_GB`. It refuses to overwrite an existing disk. Nothing is created until
`--apply` is supplied. See the [virt-install manual](https://github.com/virt-manager/virt-manager/blob/main/man/virt-install.rst).

The shell retains `dcleanup`, `del_stopped NAME...`, and `relies_on NAME...`.
They use Docker's native operations and confirmation prompts; no container volumes
are automatically pruned. Image cleanup preserves images referenced by stopped
containers too. [Docker's image-pruning behavior](https://docs.docker.com/reference/cli/docker/image/prune/).

## Desktop and passwords

`passmenu` uses Vicinae's menu on Wayland, with bemenu/X11 dmenu fallbacks. `--type`
needs wtype on Wayland or xdotool on X11. Passwords are not passed as process
arguments. This optional command is separate from Super+P, which still opens
Bitwarden on the current setup.

`keyboard-backlight` discovers a keyboard LED rather than assuming Apple hardware.
Set `KEYBOARD_BACKLIGHT_DEVICE` to select one explicitly. The current machine
exposes no compatible keyboard backlight; `info` reports that without changing LEDs.

`xname` without arguments prints the active Hyprland window's JSON for writing rules;
an explicit X11 window ID keeps the original xprop inspection behavior.

## GnuPG, kernel checks, and optional application settings

GnuPG preferences remain available in `.gnupg/`, without a hardcoded signing key,
retired keyserver, or pinned historical cipher preferences. They are not installed
by default. To install only the display preferences:

```sh
python3 scripts/dotfiles.py install --only .gnupg/gpg.conf
```

`gpg-agent.conf` is a separate opt-in; review it before installing because it also
enables the agent's SSH endpoint. Existing keys and the desktop SSH agent remain
outside this repository's default installation.

For focused kernel checks, use `check-kconfig --flag BPF --flag SECCOMP`, or supply
a saved kernel config as the first argument. The original broader groups remain
available when no flags are supplied; they include optional/historical features
and are not a current security certification for this machine.

IRC themes and plugins remain under `.irssi/`; install only the additions you want
if you use Irssi. Server identities and runtime state are excluded by `.gitignore`.
The small `.rainbow_config.json` preferences are also retained for optional use.
