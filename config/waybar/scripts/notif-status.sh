#!/bin/bash
# Emit JSON for the custom/notif waybar module.
# Left-click  → dunstctl set-paused toggle  (wired in config.jsonc)
# Right-click → dunstctl history-clear      (wired in config.jsonc)
# Middle-click→ notif-history.sh            (wired in config.jsonc)

paused=$(dunstctl is-paused 2>/dev/null)

if [ "$paused" = "true" ]; then
    echo '{"text":"󰂛","class":"muted","tooltip":"Notifications paused"}'
else
    echo '{"text":"󰂚","tooltip":"Notifications active"}'
fi
