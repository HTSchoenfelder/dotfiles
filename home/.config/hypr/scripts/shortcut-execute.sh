#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
    key=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window>"
    exit 1
fi

window=$(cat "/tmp/window-for-key-${key}" | xargs | sed 's/|/\\|/g')
echo "window:${window}"

if [ -z "$window" ]; then
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Error: No window set for key ${key}."
    exit 1
fi

hyprctl dispatch focuswindow "$window"