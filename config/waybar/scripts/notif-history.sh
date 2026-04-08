#!/bin/bash
# Show dunst notification history via wofi (middle-click on bell).
# Selecting an entry removes it from history.

history=$(dunst-history)
entries=$(echo "$history" | jq -r '.[] | "\(.appname): \(.summary)\t\(.id)"')

[ -z "$entries" ] && exit 0

selection=$(echo "$entries" | wofi --show dmenu --prompt "Notification History" --insensitive)
[ -z "$selection" ] && exit 0

notif_id=$(echo "$selection" | awk -F'\t' '{print $2}')
dunstctl history-rm "$notif_id"
