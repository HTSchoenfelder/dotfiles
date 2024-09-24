#!/bin/bash

if [ "$#" -eq 1 ]; then
    title=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window>"
    exit 1
fi

chosen=$(hyprctl clients -j | jq -r '.[].title' | grep "${title}" | tofi | xargs | sed 's/|/\\|/g' )

[ -z "$chosen" ] && exit

window="title:${chosen}"
echo "window:${window}"

hyprctl dispatch focuswindow "$window"