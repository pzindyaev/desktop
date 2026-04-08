#!/bin/bash
# Select default audio source (mic) via wofi, mirroring eww source-menu

devices=$(pwdevices source)
entries=$(echo "$devices" | jq -r '.[] | "󰍬 \(.name)\t\(.id)"')

selection=$(echo "$entries" | wofi --show dmenu --prompt "Audio Input" --insensitive)
[ -z "$selection" ] && exit 0

device_id=$(echo "$selection" | awk -F'\t' '{print $2}')
wpctl set-default "$device_id"
