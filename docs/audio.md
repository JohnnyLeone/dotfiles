# Soundcraft Ui24R audio

PipeWire exposes three stereo playback devices and the existing mono microphone:

| Device | PipeWire node | Ui24R USB channels |
| --- | --- | --- |
| Ui24R Main (AUX 0/1) | `ui24r_aux01` | Playback AUX0 / AUX1 |
| Ui24R Music (AUX 2/3) | `ui24r_aux23` | Playback AUX2 / AUX3 |
| Ui24R Voice (AUX 4/5) | `ui24r_aux45` | Playback AUX4 / AUX5 |
| Ui24R Mic 1 | `ui24r_mic01` | Capture AUX0 → mono |

AUX numbers are PipeWire's zero-based USB channel positions. Configure the mixer’s
USB returns and internal routing to match; these names do not configure its
physical AUX buses. Voice is an output for incoming call/chat audio; Mic 1 remains
the input for your microphone.

The loopbacks target the existing Soundcraft `pro-output-0` / `pro-input-0` nodes.
Keep the interface on its **Pro Audio** profile. On another machine, compare
`wpctl status -n` and `wpctl inspect NODE_ID` with `target.object` in the config
files; a different USB identity can require updating those targets.

## Install and activate

`make install` includes these files. To install only the audio configuration:

```sh
cd ~/dotfiles
python3 scripts/dotfiles.py install \
  --only .config/pipewire/pipewire.conf.d/51-ui24r-aux01.conf \
  --only .config/pipewire/pipewire.conf.d/52-ui24r-mic01.conf \
  --only .config/pipewire/pipewire.conf.d/53-ui24r-aux23.conf \
  --only .config/pipewire/pipewire.conf.d/54-ui24r-aux45.conf \
  --only .config/pipewire/pipewire.conf.d/raop-discover.conf
```

The installer backs up the previous files and links each file separately. It
also retains the existing AirPlay discovery module and its 50 ms latency setting.

After config changes, restart the audio services (this briefly interrupts audio):

```sh
systemctl --user restart pipewire pipewire-pulse wireplumber
wpctl status -n
```

## Route applications

Use `wpctl status -n` to find the Main sink's current numeric ID, then
`wpctl set-default ID` to use it for ordinary desktop audio. IDs change across
restarts. The main node's name `ui24r_aux01` is retained from the original setup
so existing saved routing continues to refer to it.

Select **Ui24R Music (AUX 2/3)** in your music player's output selector and
**Ui24R Voice (AUX 4/5)** in your call application's speaker/output selector.
Select **Ui24R Mic 1** as the call application's microphone.

For applications without a device selector, use pavucontrol's **Playback** tab
while the app is playing audio to move its stream to the appropriate output.
WirePlumber normally remembers these per-application selections. This config
creates the devices; it does not classify applications automatically.

All playback devices accept normal stereo FL/FR and map left/right directly to
their assigned pair with `stream.dont-remix = true`, following PipeWire's
[virtual sink loopback configuration](https://docs.pipewire.org/page_module_loopback.html).
