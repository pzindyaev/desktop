#!/bin/bash
# Power menu via wofi, mirroring eww power-menu

choice=$(printf "󰐥 Shutdown\n󰜉 Reboot" | wofi --show dmenu --prompt "Power" --insensitive)

case "$choice" in
    *Shutdown) systemctl poweroff ;;
    *Reboot)   systemctl reboot ;;
esac
