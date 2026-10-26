# Cleanup review

Reviewed on 2026-10-26 for the current Arch/Hyprland desktop.
Age or a missing optional dependency alone was not a reason to remove a tool.

## Retained and adapted

- GitHub PR listing and fork synchronization use `gh` rather than old hand-written API pagination.
- VM creation uses native, unprivileged libvirt, replacing a hardcoded Docker KVM container and bridge.
- `passmenu` uses Vicinae on Wayland, retaining clipboard and optional typing support.
- Keyboard lighting uses `brightnessctl`, replacing a Mac-only sysfs path.
- Container cleanup/start helpers remain; native app names are no longer overridden by containers.
- Git dates use GNU date for correct UTC conversion across calendar boundaries; `gcutc` commits in UTC.
- GPG signing remains interactive, with no Debian-specific package lookup or default key publication.
- The read-only kernel checker is retained, with focused flag queries, fixed flag matching/exit handling, and cgroup-v2 detection.
  Its optional historical flag groups are an inspection aid, not a current security certification.
- IRC themes/plugins, GnuPG preference templates, and the small Rainbowstream preference file remain optional.
- GTK settings now use installed Adwaita/Noto/cursor resources; shell and editor preferences remain active.

## Removed from the working repository

| Path | Reason |
| --- | --- |
| `.i3` | Sway-style shortcuts are already carried into the active Hyprland Lua config. |
| `.config/sway` | Previous compositor/output configuration; active monitor and input settings are in Hyprland. |
| `.config/waybar` | The useful modules were migrated to ashell, including native media-player support. |
| `.config/hypr/legacy` | Historical hyprlang snapshot already backed up; the active config is Lua. |
| `.Xdefaults` | URxvt/Xresources alias replaced by the active Kitty config. |
| `.Xresources` | URxvt-specific settings and hardcoded old DPI/font settings; current Kitty/GTK settings cover the useful parts. |
| `.urxvt` | URxvt clipboard extension superseded by Kitty and Wayland clipboard helpers. |
| `.alacritty.yml` | Unused YAML terminal setup; the terminal workflow and colors have a maintained Kitty config. |
| `.color` | ICC profiles for the former MacBook Air and PB278Q, not the current ASUS display. |
| `.xprofile` | Xorg startup commands duplicated or superseded by Hyprland autostart, input, and compositor behavior. |
| `.config/environment.d` | Comment-only placeholder; session variables are provided by the compositor. |
| `.travis.yml` | Old Docker/Travis test setup superseded by local make check. |
| `test.sh` | Old Docker/ShellCheck runner superseded by scripts/check.sh. |
| `bin/fancy-i3lock` | Docker/scrot/i3lock screenshot locker superseded by the working hyprlock OLED setup. |
| `bin/install.sh` | Old root installer changes sudoers/fstab and installs the former Xorg stack; superseded by the file-level installer. |
| `etc` | Files for the former Xorg hardware, MAC addresses, container services, and system-wide policies; useful VM/GPG workflows are kept as user tools. |
| `fonts` | Uninitialized Powerline font submodule; current fonts are installed through the OS. |
| `.gitmodules` | Metadata for the removed, uninitialized fonts submodule. |

The former hardware-specific `dell_monitor` shell function was removed because the
current display settings are explicitly maintained in Hyprland. `xname` now also
reports the active native Hyprland window while retaining XWayland inspection.
The shared ignore patterns were retained, including cross-platform/project patterns;
a malformed trash-file pattern was fixed.
The `gitio` link-creation function was removed because
[GitHub no longer accepts new git.io links](https://github.blog/changelog/2022-01-11-git-io-no-longer-accepts-new-urls/).
The optional `govendorcheck` helper remains, with the former owner's hardcoded
repository prefix removed.

## Recovery

A complete snapshot is saved outside the repo at
`~/.local/state/dotfiles/backups/20261026-234714-cleanup/repository-before-cleanup.tar.gz`.
Individual removed files are also in that backup's `removed/` directory, with the
per-path rationale in `removal-review.json`. Git history remains intact.
The uninitialized fonts gitlink was removed from the index along with its metadata;
other cleanup edits are left uncommitted for review.
