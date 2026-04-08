#!/bin/bash
# Bluetooth device toggle via wofi, mirroring eww bt-menu

devices=$(btstate)
entries=$(echo "$devices" | jq -r '.[] | "\(if .connected then "󰂱" else "󰂯" end) \(.name)\t\(.mac)"')

selection=$(echo "$entries" | wofi --show dmenu --prompt "Bluetooth" --insensitive)
[ -z "$selection" ] && exit 0

mac=$(echo "$selection" | awk -F'\t' '{print $2}')
btctl "$mac"
