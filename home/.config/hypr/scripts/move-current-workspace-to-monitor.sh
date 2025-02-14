#!/usr/bin/env bash

if [ "$#" -eq 1 ]; then
    monitor=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <monitor>"
    exit 1
fi

hyprctl dispatch movecurrentworkspacetomonitor "$monitor"
hyprctl dispatch workspace previous
hyprctl dispatch workspace previous