-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

hl.monitor({
    output = "DP-1",
    mode = "2560x1440@143.97301",
    position = "0x490",
    scale = "1",
})

hl.monitor({
    output = "DP-2",
    mode = "2560x1440@144.00",
    position = "-1440x0",
    scale = "1",
    transform = 3,
})

-- monitor = DP-3, 1920x1080@60.00,2560x100,1, transform,3
hl.monitor({
    output = "DP-3",
    mode = "2560x1440@144.00",
    position = "2560x0",
    scale = "1",
    transform = 1,
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.workspace_rule({
    workspace = "1",
    monitor = "DP-2",
    default = true,
})

hl.workspace_rule({
    workspace = "2",
    monitor = "DP-1",
    default = true,
})

hl.workspace_rule({
    workspace = "3",
    monitor = "DP-3",
    default = true,
})

hl.workspace_rule({
    workspace = "4",
    monitor = "DP-2",
    default = false,
})

hl.workspace_rule({
    workspace = "5",
    monitor = "DP-1",
    default = false,
})

hl.workspace_rule({
    workspace = "6",
    monitor = "DP-3",
    default = false,
})

