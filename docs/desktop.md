# Desktop configuration

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

Brightness keys use `dotfiles-brightness`: an active ASUS PG32UCDM3 is adjusted
through DDC/CI in five-point steps; an active internal eDP panel uses the existing
`brightnessctl` curve. Holding a key drops overlapping DDC requests so they do
not queue after release. Manual changes coordinate with idle dimming and are
not overwritten on resume. A failed monitor query/control does not fall back to
changing an inactive panel. Ashell's settings panel also provides **Display
brightness − / +** buttons using the same helper. Its built-in brightness slider
still represents the internal backlight; use the new buttons or brightness keys
for the external OLED.

Hyprland groups approximate tabbed containers; dwindle has no exact equivalent
for i3 stacked containers or parent-container focus. Edit
`.config/hypr/hyprland.lua`, then use Super+Shift+C to validate and reload.
Hypridle and hyprlock are separate programs and retain their `.conf` format.

Rendering stays lightweight: blur, shadows, and animations are off; hardware
cursors, damage tracking, and variable frame rendering remain enabled. Keep
`new_render_scheduling = true` for this APU. A fullscreen Firefox trial with
`direct_scanout = 1` still reported `CANDIDATE` blocked and did not scan out;
the game-only auto setting `2` is retained. This is an eligibility result, not
a measured FPS improvement. 4K/120 Hz and 1.333333 scaling remain unchanged.

## Dark appearance

GTK 3 and GTK 4 use their built-in Adwaita dark theme. Set the matching desktop
preferences once; they persist in dconf and are exposed to applications through
the GTK settings portal:

```sh
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
```

Install `qt5ct` and `qt6ct` with `sudo pacman -S --needed qt5ct qt6ct` for Qt 5
and Qt 6 dark palettes. Both use Fusion with the packaged darker color scheme
and portal file dialogs through `QT_QPA_PLATFORMTHEME=qt5ct` (qt6ct also accepts
this name), set in the UWSM environment and the plain Hyprland fallback.
Restart applications after changing this
environment, or log out and back in to cover every launcher and service.
Libadwaita and sandboxed applications receive the dark preference through the
existing settings portal. Applications with their own appearance setting need
to use System or Dark; applications that do not support dark appearance cannot
be made dark by a desktop preference alone.

## UWSM sessions

Ly remains the login manager. Install `uwsm` with `sudo pacman -S --needed uwsm`,
then select **Hyprland (uwsm-managed)** in Ly at your next login. The regular
Hyprland entry still works as a fallback. Switching requires logging out; a
configuration reload does not turn the current session into a UWSM session.

The installer links `~/.config/uwsm/env` (cursor theme, size, and helper PATH),
`env-hyprland` (Hyprland variables and the session marker), and user service
configuration. Enable startup once, without starting duplicate daemons now:

```sh
systemctl --user daemon-reload
systemctl --user enable ashell.service vicinae.service hypridle.service udiskie.service
```

UWSM starts these services after Hyprland exports its display variables through
`uwsm finalize`. The packaged units provide logging and restart behavior. Unit
conditions select the UWSM session; plain Hyprland uses its original startup
commands, so the two paths do not launch duplicate daemons.

`dotfiles-app COMMAND [ARGUMENTS...]` uses `uwsm app --` in a managed session
and runs the command directly otherwise. Terminal/file-manager shortcuts,
Bitwarden, mpv, Ashell's application buttons, and Vicinae's Applications launch
prefix use this helper. Short IPC and screenshot commands stay direct.

Super+Shift+E still asks for confirmation. In a managed session, the logout
helper asks apps to close with `hyprshutdown --no-exit --no-fork`, then runs
`uwsm stop`; the regular session retains its previous logout path.
Ashell's logout button uses the same session-aware helper.

After logging into UWSM, check the result with:

```sh
uwsm check is-active compositor-only
systemctl --user status ashell vicinae hypridle udiskie
journalctl --user -b -u hypridle -u ashell -u vicinae -u udiskie
```

To return to plain Hyprland, log out and select its regular entry in Ly. Keep the
UWSM service conditions in place while both startup paths are available.

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
| 60 seconds without input, unless inhibited | Reduce ASUS OLED brightness by 20 points (70 → 50); restore on activity |
| 180 seconds without input | Lock |
| 240 seconds without input | Turn displays off; wake on activity |

Video/presentation inhibitors prevent automatic locking and display-off. The
bar-only timeout still hides static UI, and preserves a manually hidden bar.
Use Super+Ctrl+B to control visibility. Black desktop/terminal backgrounds,
dimmer bar text, and a subdued lock-screen clock reduce static bright content.
Kitty applies config changes to new terminals or after Ctrl+Shift+F5.

Idle dimming uses `ddcutil` and DDC/CI on the external `PG32UCDM3`, rather than
the Steam Deck's internal backlight. Install it with `sudo pacman -S --needed ddcutil`
and enable DDC/CI in the monitor's menu if necessary. Log out/in after installation
if I²C access is denied. Check access with `ddcutil --model PG32UCDM3 getvcp 10`.
The helper saves the current brightness, subtracts 20 percentage points (minimum 1),
and restores the saved value when input resumes. Video/presentation inhibitors
also prevent dimming. After editing `hypridle.conf`, restart hypridle to apply it.

Use moderate SDR brightness and the monitor's own OLED Care protections, including
screen movement, logo dimming, proximity detection, and automatic pixel cleaning.
Keep power connected while cleaning runs. These measures reduce exposure rather
than guarantee prevention. [ASUS model guidance](https://rog.asus.com/us/monitors/27-to-31-5-inches/rog-swift-oled-pg32ucdm-gen3-pg32ucdm3/).

