-- Hyprland's native Lua configuration with optional UWSM session management.
-- Steam Deck with ASUS OLED, dwindle layout, and keyboard-driven navigation.

local app = "~/.local/bin/dotfiles-app "
local terminal = app .. "kitty"
local helper = "~/.local/bin/dotfiles-hypr "
local bar = "~/.local/bin/dotfiles-bar "
local mod = "SUPER"
local dsp = hl.dsp

-- ASUS PG32UCDM3: preserve 4K/120 Hz and the existing desktop scaling.
hl.monitor({ output = "DP-1", mode = "3840x2160@120", position = "0x0", scale = 1.333333 })
hl.monitor({ output = "eDP-1", disabled = true })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local managed_session = os.getenv("DOTFILES_UWSM_SESSION") == "1"
-- UWSM loads these before starting Hyprland. Keep plain sessions usable too.
if not managed_session then
    hl.env("XCURSOR_THEME", "Adwaita")
    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
end

-- The start event runs once per session, never during an ordinary config reload.
hl.on("hyprland.start", function()
    if managed_session then
        -- Export compositor-created variables and release session services.
        hl.exec_cmd("uwsm finalize")
    else
        -- Fallback for Ly's regular Hyprland entry; service drop-ins exclude it.
        hl.exec_cmd("vicinae server")
        hl.exec_cmd("ashell")
        hl.exec_cmd("udiskie --tray")
        hl.exec_cmd("command -v hypridle >/dev/null 2>&1 && hypridle")
    end
end)

hl.config({
    xwayland = { force_zero_scaling = true },
    general = {
        gaps_in = 6,
        gaps_out = 18,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(6f8fd6cc)", "rgba(80a45fcc)" }, angle = 45 },
            inactive_border = "rgba(30344188)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
        rounding_power = 2,
        dim_inactive = true,
        dim_strength = 0.08,
        shadow = { enabled = false },
        blur = { enabled = false },
    },
    animations = { enabled = false },
    dwindle = { preserve_split = true },
    misc = {
        focus_on_activate = true,
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        background_color = "rgb(000000)",
        vrr = 2,
    },
    render = {
        -- Attempt direct scanout for game content.
        direct_scanout = 2,
        new_render_scheduling = true,
    },
    cursor = {
        sync_gsettings_theme = true,
        inactive_timeout = 15,
        no_hardware_cursors = 2,
        no_break_fs_vrr = 2,
    },
    input = {
        kb_layout = "eu,de",
        kb_variant = ",nodeadkeys",
        kb_options = "caps:escape,grp:alt_shift_toggle",
        follow_mouse = 1,
        touchpad = { natural_scroll = false },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Launchers, window controls, and OLED bar visibility.
hl.bind(mod .. " + Return", dsp.exec_cmd(terminal))
hl.bind(mod .. " + Q", dsp.exec_cmd(terminal))
hl.bind(mod .. " + SHIFT + Q", dsp.window.close())
hl.bind(mod .. " + D", dsp.exec_cmd("vicinae toggle"))
hl.bind(mod .. " + C", dsp.exec_cmd(helper .. "clipboard"))
hl.bind(mod .. " + P", dsp.exec_cmd(helper .. "password"))
hl.bind(mod .. " + CTRL + L", dsp.exec_cmd(helper .. "lock"))
hl.bind(mod .. " + CTRL + B", dsp.exec_cmd(bar .. "toggle"))
hl.bind(mod .. " + SHIFT + Return", dsp.exec_cmd(app .. 'xdg-open "$HOME"'))
hl.bind(mod .. " + SHIFT + C", dsp.exec_cmd(helper .. "reload"))
hl.bind(mod .. " + F", dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + Space", dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + Space", dsp.exec_cmd(helper .. "focus-mode"))
hl.bind(mod .. " + B", dsp.layout("preselect r"))
hl.bind(mod .. " + V", dsp.layout("preselect d"))
hl.bind(mod .. " + E", dsp.layout("togglesplit"))

-- Hyprland groups provide the existing tabbed-window workflow.
hl.bind(mod .. " + W", dsp.group.toggle())
hl.bind(mod .. " + S", dsp.group.next())
hl.bind(mod .. " + SHIFT + S", dsp.window.pin())
hl.bind(mod .. " + Tab", dsp.group.next())
hl.bind(mod .. " + SHIFT + Tab", dsp.group.prev())
hl.bind(mod .. " + minus", dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + SHIFT + minus", dsp.window.move({ workspace = "special:scratchpad", follow = false }))

hl.bind(mod .. " + T", dsp.exec_cmd(helper .. "media"))
hl.bind("Print", dsp.exec_cmd(helper .. "screenshot area"))
hl.bind("SHIFT + Print", dsp.exec_cmd(helper .. "screenshot full"))
hl.bind(mod .. " + Print", dsp.exec_cmd(helper .. "screenshot window"))

local directions = {
    { "H", "left" }, { "J", "down" }, { "K", "up" }, { "L", "right" },
    { "left", "left" }, { "down", "down" }, { "up", "up" }, { "right", "right" },
}
for _, pair in ipairs(directions) do
    hl.bind(mod .. " + " .. pair[1], dsp.focus({ direction = pair[2] }))
    hl.bind(mod .. " + SHIFT + " .. pair[1], dsp.window.move({ direction = pair[2] }))
end

for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(mod .. " + " .. key, dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. key, dsp.window.move({ workspace = workspace }))
end

hl.bind(mod .. " + CTRL + SHIFT + left", dsp.workspace.move({ monitor = "l" }))
hl.bind(mod .. " + CTRL + SHIFT + right", dsp.workspace.move({ monitor = "r" }))
hl.bind(mod .. " + mouse_down", dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", dsp.window.drag())
hl.bind(mod .. " + mouse:273", dsp.window.resize())

hl.bind(mod .. " + R", dsp.submap("resize"))
hl.define_submap("resize", function()
    local sizes = {
        { "H", -10, 0 }, { "J", 0, 10 }, { "K", 0, -10 }, { "L", 10, 0 },
        { "left", -10, 0 }, { "down", 0, 10 }, { "up", 0, -10 }, { "right", 10, 0 },
    }
    for _, size in ipairs(sizes) do
        hl.bind(size[1], dsp.window.resize({ x = size[2], y = size[3], relative = true }), { repeating = true })
    end
    hl.bind("Return", dsp.submap("reset"))
    hl.bind("Escape", dsp.submap("reset"))
end)

-- Keep the existing two-step logout confirmation.
hl.bind(mod .. " + SHIFT + E", dsp.exec_cmd("notify-send 'Exit Hyprland?' 'Enter confirms; Escape cancels.'"))
hl.bind(mod .. " + SHIFT + E", dsp.submap("exit-confirm"))
hl.define_submap("exit-confirm", function()
    hl.bind("Return", function()
        hl.dispatch(dsp.submap("reset"))
        hl.exec_cmd(helper .. "exit")
    end)
    hl.bind("Escape", dsp.submap("reset"))
end)

local repeated_media = {
    { "XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
    { "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
    { "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
    { "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" },
    { "XF86MonBrightnessUp", "~/.local/bin/dotfiles-brightness up" },
    { "XF86MonBrightnessDown", "~/.local/bin/dotfiles-brightness down" },
}
for _, binding in ipairs(repeated_media) do
    hl.bind(binding[1], dsp.exec_cmd(binding[2]), { locked = true, repeating = true })
end
local media = {
    { "XF86AudioNext", "playerctl next" },
    { "XF86AudioPause", "playerctl play-pause" },
    { "XF86AudioPlay", "playerctl play-pause" },
    { "XF86AudioPrev", "playerctl previous" },
}
for _, binding in ipairs(media) do
    hl.bind(binding[1], dsp.exec_cmd(binding[2]), { locked = true })
end

-- Keep Firefox bright when another window has focus.
hl.window_rule({
    name = "firefox-no-inactive-dimming",
    match = { class = "^firefox$" },
    no_dim = true,
})
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})
hl.layer_rule({ name = "vicinae-no-animation", match = { namespace = "vicinae" }, no_anim = true })
