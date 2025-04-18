#! /usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 \"shortcut\""
    exit 1
fi

SHORTCUT=$1
ACTIVEWINDOW=$(hyprctl -j activewindow | jq -r '.class')
NEW_SHORTCUT=$SHORTCUT
if [ "$ACTIVEWINDOW" == "google-chrome" ]; then
    declare -A SHORTCUT_MAP=(
        ["CTRL, p"]="CTRL SHIFT, a"
        ["CTRL, j"]="CTRL SHIFT, TAB"
        ["CTRL, k"]="CTRL, TAB"
        ["CTRL, h"]="ALT, LEFT"
        ["CTRL, l"]="ALT, RIGHT"
    )

    if [[ -n "${SHORTCUT_MAP[$SHORTCUT]}" ]]; then
        NEW_SHORTCUT=${SHORTCUT_MAP[$SHORTCUT]}
    fi
fi

hyprctl dispatch sendshortcut "$NEW_SHORTCUT, activewindow"
# hyprctl notify -1 5000 "rgb(ff1ea3)" "Sending shortcut: $NEW_SHORTCUT"