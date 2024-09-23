#!/bin/bash
[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 5000 "rgb(ff1ea3)" "choose-window"

if [ "$#" -eq 4 ]; then
    title=$1
    class=$2
    workspaceId=$3
    specialWorkspaceName=$4    
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window> <class> <workSpaceId> <specialWorkspaceName>"
    hyprctl notify -1 5000 "rgb(ff1ea3)" "$window $class $workspaceId $specialWorkspaceName"
    exit 1
fi

chosen=$(hyprctl clients -j | jq -r '.[].title' | grep "${title}" | tofi | awk '{print $1}')

[ -z "$chosen" ] && exit

$HOME/.config/hypr/scripts/select-window.sh "title:${chosen}" "$class" "$workspaceId" "$specialWorkspaceName"