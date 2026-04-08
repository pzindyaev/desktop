#!/bin/bash
# Select default audio sink via wofi, mirroring eww sink-menu

devices=$(pwdevices sink)
entries=$(echo "$devices" | jq -r '.[] | "󰕾 \(.name)\t\(.id)"')

selection=$(echo "$entries" | wofi --show dmenu --prompt "Audio Output" --insensitive)
[ -z "$selection" ] && exit 0

device_id=$(echo "$selection" | awk -F'\t' '{print $2}')
wpctl set-default "$device_id"
