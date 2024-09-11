#!/bin/bash
hyprctl notify -1 5000 "rgb(ff1ea3)" "choose-window"

chosen=$(hyprctl clients -j | jq -r '.[].title' | tofi | awk '{print $1}')

[ -z "$chosen" ] && exit

activeWorkspaceId=$(hyprctl activeworkspace -j | jq '.id')
window="title:${chosen}"
[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 5000 "rgb(ff1ea3)" "Active Workspace: $activeWorkspaceId, Chosen Window: $window"
hyprctl dispatch movetoworkspace "$activeWorkspaceId,$window"