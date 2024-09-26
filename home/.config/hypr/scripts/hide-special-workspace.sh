#! /usr/bin/env bash

[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 5000 "rgb(ff1ea3)" "hide-special-workspace"

# close special workspace on focused monitor if one is present
active=$(hyprctl -j monitors | jq --raw-output '.[] | select(.focused==true).specialWorkspace.name | split(":") | if length > 1 then .[1] else "" end')

if [[ ${#active} -gt 0 ]]; then
    hyprctl dispatch togglespecialworkspace "$active"
fi

hyprctl dispatch workspace "$1"