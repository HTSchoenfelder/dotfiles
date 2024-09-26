#! /usr/bin/env bash
sleep 0.5
hyprctl dispatch submap reset
[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 500 "rgb(ff1ea3)" "reset"
